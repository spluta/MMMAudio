from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import *
from mmm_utils.functions import *
from mmm_dsp.Filters import Lag
from mmm_dsp.Delays import LP_Comb

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_dsp.Reverb import Freeverb

struct FreeverbSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var buffer: InterleavedBuffer

    var num_chans: Int64

    var play_buf: PlayBuf

    var freeverb: Freeverb[2]
    var room_size: Float64
    var verb_lpf: Float64
    var added_space: SIMD[DType.float64, 2]
    var mix: Float64
    

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = InterleavedBuffer(self.world_ptr, "resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_buf = PlayBuf(self.world_ptr)

        self.freeverb = Freeverb[2](self.world_ptr)
        self.room_size = 0.9
        self.verb_lpf = 1000.0
        self.added_space = SIMD[DType.float64, 2](0.5, 0.5)
        self.mix = 0.1

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()

        out = self.play_buf.next[N=2](self.buffer, 0, 1.0, True)

        out = self.freeverb.next(out, self.room_size, self.verb_lpf, self.added_space) * 0.2 * self.mix + out * (1.0 - self.mix)

        return out

    fn __repr__(self) -> String:
        return String("BufSynth")

    fn get_msgs(mut self: Self):

        fader1 = self.world_ptr[0].get_msg("/fader1") 
        if fader1: 
            self.room_size = fader1.value()[0]
        fader2 = self.world_ptr[0].get_msg("/fader2") 
        if fader2: 
            freq = linexp(fader2.value()[0], 0.0, 1.0, 200.0, 10000.0)
            self.verb_lpf = freq
        fader3 = self.world_ptr[0].get_msg("/fader3") 
        if fader3: 
            self.added_space = SIMD[DType.float64, 2](fader3.value()[0], fader3.value()[0]*0.99)
        fader4 = self.world_ptr[0].get_msg("/fader4")
        if fader4: 
            self.mix = fader4.value()[0]


struct Freeverb_Graph(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var freeverb_synth: FreeverbSynth  # Instance of the FreeverbSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.freeverb_synth = FreeverbSynth(world_ptr)

    fn __repr__(self) -> String:
        return String("Freeverb_Graph")

    fn next(mut self: Freeverb_Graph) -> SIMD[DType.float64, 2]:
        #return SIMD[DType.float64, 2](0.0)
        return self.freeverb_synth.next()  # Return the combined output sample
