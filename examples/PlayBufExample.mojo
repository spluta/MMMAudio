from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messenger import Messenger
from mmm_src.MMMTraits import *
from mmm_utils.functions import *
from mmm_dsp.Filters import Lag

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Filters import VAMoogLadder

struct BufSynth(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld] 
    var buffer: Buffer

    var num_chans: Int64

    var play_buf: PlayBuf
    var play_rate: Float64
    
    var moog: VAMoogLadder[2, 1] # 2 channels, os_index == 1 (2x oversampling)
    var lpf_freq: Float64
    var lpf_freq_lag: Lag
    var messenger: Messenger

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w 

        # load the audio buffer 
        self.buffer = Buffer("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_rate = 1.0

        self.play_buf = PlayBuf(self.w)

        self.moog = VAMoogLadder[2, 1](self.w)
        self.lpf_freq = 20000.0
        self.lpf_freq_lag = Lag(self.w, 0.1)

        self.messenger = Messenger(self.w)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.lpf_freq, "lpf_freq")
        self.messenger.update(self.play_rate, "play_rate")

        out = self.play_buf.next[N=2](self.buffer, 0, self.play_rate, True)

        freq = self.lpf_freq_lag.next(self.lpf_freq)
        out = self.moog.next(out, freq, 1.0)
        return out

    fn __repr__(self) -> String:
        return String("BufSynth")


struct PlayBufExample(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]

    var buf_synth: BufSynth  # Instance of the GrainSynth

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w

        self.buf_synth = BufSynth(w)  

    fn __repr__(self) -> String:
        return String("PlayBufExample")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        #return SIMD[DType.float64, 2](0.0)
        return self.buf_synth.next()  # Return the combined output sample
