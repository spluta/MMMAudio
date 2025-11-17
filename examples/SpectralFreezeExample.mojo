from mmm_src.MMMWorld import *
from mmm_utils.Messengers import Messenger
from mmm_dsp.PlayBuf import PlayBuf
from mmm_dsp.FFT_Processors import SpectralFreeze

# this really should have a window size of 8192 or more, but the numpy FFT seems to barf on this
alias window_size = 2048

struct SpectralFreezeExample(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var play_buf: PlayBuf
    var spectral_freeze: SpectralFreeze[window_size]
    var m: Messenger
    var dur_mult: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        self.world_ptr = world_ptr
        self.buffer = Buffer("resources/Shiverer.wav")
        self.play_buf = PlayBuf(world_ptr)
        self.spectral_freeze = SpectralFreeze[window_size](world_ptr)
        self.m = Messenger(world_ptr)
        self.dur_mult = 20.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        out = self.play_buf.next[2](self.buffer, 0, 1)
        out = self.spectral_freeze.next(out)
        return out

