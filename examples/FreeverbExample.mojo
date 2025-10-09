from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
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
    var buffer: Buffer

    var num_chans: Int64

    var play_buf: PlayBuf

    var freeverb: Freeverb[2]
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = Buffer("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_buf = PlayBuf(self.world_ptr)
        self.freeverb = Freeverb[2](self.world_ptr)
        self.messenger = Messenger(self.world_ptr)


    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        room_size = self.messenger.val("room_size", 0.9)
        lpf_comb = self.messenger.val("lpf_comb", 1000.0)
        added_space = self.messenger.val("added_space", 0.5)
        added_space_simd = SIMD[DType.float64, 2](added_space, added_space * 0.99)
        mix = self.messenger.val("mix", 0.1)

        out = self.play_buf.next[N=2](self.buffer, 0, 1.0, True)

        out = self.freeverb.next(out, room_size, lpf_comb, added_space_simd) * 0.2 * mix + out * (1.0 - mix)

        return out

    fn __repr__(self) -> String:
        return String("BufSynth")


struct FreeverbExample(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var freeverb_synth: FreeverbSynth  # Instance of the FreeverbSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.freeverb_synth = FreeverbSynth(world_ptr)

    fn __repr__(self) -> String:
        return String("Freeverb_Graph")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        #return SIMD[DType.float64, 2](0.0)
        return self.freeverb_synth.next()  # Return the combined output sample
