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

    var play_buf: PlayBuf
    var playback_speed: Float64
    
    var moog: VAMoogLadder[2, 1] # 2 channels, os_index == 1 (2x oversampling)
    var lpf_freq: Float64
    var lpf_freq_lag: Lag

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = InterleavedBuffer(self.world_ptr, "resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.playback_speed = 1.0

        self.play_buf = PlayBuf(self.world_ptr)

        self.moog = VAMoogLadder[2, 1](self.world_ptr)
        self.lpf_freq = 20000.0
        self.lpf_freq_lag = Lag(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()

        out = self.play_buf.next[N=2](self.buffer, 0, self.playback_speed, True)

        freq = self.lpf_freq_lag.next(self.lpf_freq, 0.1)
        out = self.moog.next(out, freq, 1.0)
        return out

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

struct PlayBufExample(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var buf_synth: BufSynth  # Instance of the GrainSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.buf_synth = BufSynth(world_ptr)  

    fn __repr__(self) -> String:
        return String("PlayBufExample")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        #return SIMD[DType.float64, 2](0.0)
        return self.buf_synth.next()  # Return the combined output sample
