from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messenger import Messenger

from mmm_utils.functions import *
from mmm_dsp.Delays import LP_Comb

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_dsp.Reverb import Freeverb

struct FreeverbSynth(Copyable, Movable):
    var w: UnsafePointer[MMMWorld] 
    var buffer: Buffer

    var num_chans: Int64

    var play_buf: PlayBuf

    var freeverb: Freeverb[2]
    var m: Messenger

    var room_size: Float64
    var lpf_comb: Float64
    var added_space: Float64
    var mix: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w 

        # load the audio buffer 
        self.buffer = SoundFile.load("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_buf = PlayBuf(self.w)
        self.freeverb = Freeverb[2](self.w)

        self.room_size = 0.9
        self.lpf_comb = 1000.0
        self.added_space = 0.5
        self.mix = 0.2

        self.m = Messenger(self.w)

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update(self.room_size,"room_size")
        self.m.update(self.lpf_comb,"lpf_comb")
        self.m.update(self.added_space,"added_space")
        self.m.update(self.mix,"mix")

        added_space_simd = SIMD[DType.float64, 2](self.added_space, self.added_space * 0.99)
        out = self.play_buf.next[N=2](self.buffer, 0, 1.0, True)
        out = self.freeverb.next(out, self.room_size, self.lpf_comb, added_space_simd) * 0.2 * self.mix + out * (1.0 - self.mix)
        return out


struct FreeverbExample(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]

    var freeverb_synth: FreeverbSynth  # Instance of the FreeverbSynth

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.freeverb_synth = FreeverbSynth(w)

    fn __repr__(self) -> String:
        return String("Freeverb_Graph")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        #return SIMD[DType.float64, 2](0.0)
        return self.freeverb_synth.next()  # Return the combined output sample
