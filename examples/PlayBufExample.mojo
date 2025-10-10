from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
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
    var play_rate: Float64
    
    var moog: VAMoogLadder[2, 1] # 2 channels, os_index == 1 (2x oversampling)
    var lpf_freq: Float64
    var lpf_freq_lag: Lag
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr 

        # load the audio buffer 
        self.buffer = Buffer("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_rate = 1.0

        self.play_buf = PlayBuf(self.world_ptr)

        self.moog = VAMoogLadder[2, 1](self.world_ptr)
        self.lpf_freq = 20000.0
        self.lpf_freq_lag = Lag(world_ptr)

        self.messenger = Messenger(self.world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.world_ptr[0].top_of_block:
            self.play_rate = self.messenger.get_val("play_rate", 1.0)
            self.lpf_freq = self.messenger.get_val("lpf_freq", 20000.0)

        out = self.play_buf.next[N=2](self.buffer, 0, self.play_rate, True)

        freq = self.lpf_freq_lag.next(self.lpf_freq, 0.1)
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
