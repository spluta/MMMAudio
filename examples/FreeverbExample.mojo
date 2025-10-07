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
    var room_size: Messenger
    var lpf_comb: Messenger
    var added_space_fader: Messenger
    var added_space: SIMD[DType.float64, 2]
    var mix: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = Buffer("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_buf = PlayBuf(self.world_ptr)
        self.freeverb = Freeverb[2](self.world_ptr)
        self.room_size = Messenger(self.world_ptr, 0.9)
        self.lpf_comb = Messenger(self.world_ptr, 1000.0)
        
        self.added_space_fader = Messenger(self.world_ptr, 0.5)
        self.added_space = SIMD[DType.float64, 2](0.5, 0.5)
        self.mix = Messenger(self.world_ptr, 0.1)

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.room_size.get_msg("room_size")
        self.lpf_comb.get_msg("lpf_comb")
        self.added_space_fader.get_msg("added_space")
        self.added_space = SIMD[DType.float64, 2](self.added_space_fader.val, self.added_space_fader.val*0.99)
        self.mix.get_msg("mix")

        out = self.play_buf.next[N=2](self.buffer, 0, 1.0, True)

        out = self.freeverb.next(out, self.room_size.val, self.lpf_comb.val, self.added_space) * 0.2 * self.mix.val + out * (1.0 - self.mix.val)

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
