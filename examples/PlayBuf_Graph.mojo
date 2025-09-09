from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import *
from mmm_utils.functions import *
from mmm_dsp.Filters import Lag

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Filters import VAMoogLadder

struct BufSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var buffer: InterleavedBuffer

    var num_chans: Int64

    var playBuf: PlayBuf
    var playback_speed: Float64
    
    var moog: List[VAMoogLadder]
    var lpf_freq: Float64
    var lpf_freq_lag: Lag

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = InterleavedBuffer(self.world_ptr, "resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        self.playback_speed = 1.0

        self.playBuf = PlayBuf(self.world_ptr, self.num_chans)  

        self.moog = List[VAMoogLadder]()
        for _ in range(self.num_chans):
            self.moog.append(VAMoogLadder(self.world_ptr)) 
        self.lpf_freq = 20000.0 
        self.lpf_freq_lag = Lag(world_ptr)

    fn next(mut self) -> List[Float64]:
        self.get_msgs()

        out = self.playBuf.next(self.buffer, self.playback_speed, True)
        
        freq = self.lpf_freq_lag.next(self.lpf_freq, 0.1)
        for i in range(self.num_chans):
            out[i] = self.moog[i].next(out[i], freq, 1.0)
        return out^

    fn __repr__(self) -> String:
        return String("BufSynth")

    fn get_msgs(mut self: Self):
        # calls to get_msg and get_midi return an Optional type
        # so you must get the value, then test the value to see if it exists, before using the value
        # get_msg returns a single list of values while get_midi returns a list of lists of values

        fader1 = self.world_ptr[0].get_msg("/fader1") # fader1 will be an Optional
        if fader1: # if fader1 is None, we do nothing
            self.playback_speed = linexp(fader1.value()[0], 0.0, 1.0, 0.25, 4.0)
        fader2 = self.world_ptr[0].get_msg("/fader2") # fader2 will be an Optional
        if fader2: # if fader2 is None, we do nothing
            freq = linexp(fader2.value()[0], 0.0, 1.0, 20.0, 20000.0)
            self.lpf_freq = freq

struct PlayBuf_Graph(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var buf_synth: BufSynth  # Instance of the GrainSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.buf_synth = BufSynth(world_ptr)  

    fn __repr__(self) -> String:
        return String("PlayBuf")

    fn next(mut self: PlayBuf_Graph) -> List[Float64]:
        return self.buf_synth.next()  # Return the combined output sample
