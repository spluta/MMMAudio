from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_src.MMMTraits import *
from mmm_utils.functions import *
from mmm_dsp.Filters import Lag

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Filters import VAMoogLadder

struct BufSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var buffer: Buffer

    var num_chans: Int64

    var play_buf: PlayBuf
    var play_rate: Messenger
    
    var moog: VAMoogLadder[2, 1] # 2 channels, os_index == 1 (2x oversampling)
    var lpf_freq: Messenger
    var lpf_freq_lag: Lag

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = Buffer("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_rate = Messenger(world_ptr, 1.0)

        self.play_buf = PlayBuf(self.world_ptr)

        self.moog = VAMoogLadder[2, 1](self.world_ptr)
        self.lpf_freq = Messenger(world_ptr, 20000.0)
        self.lpf_freq_lag = Lag(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.play_rate.get_msg("play_rate")
        self.lpf_freq.get_msg("lpf_freq")
    
        out = self.play_buf.next[N=2](self.buffer, 0, self.play_rate.val, True)

        freq = self.lpf_freq_lag.next(self.lpf_freq.val, 0.1)
        out = self.moog.next(out, freq, 1.0)
        return out

    fn __repr__(self) -> String:
        return String("BufSynth")


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
