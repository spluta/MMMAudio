from mmm_src.MMMWorld import *
from mmm_dsp.FFTProcess import *
from mmm_utils.Messengers import Messenger
from mmm_utils.Windows import WindowTypes
from mmm_dsp.PlayBuf import PlayBuf
from mmm_utils.functions import select
from mmm_utils.functions import dbamp
from mmm_dsp.FFT import FFT
from complex import ComplexFloat64
from mmm_dsp.Osc import LFSaw
from random import random_float64

# this really should have a window size of 8192 or more, but the numpy FFT seems to barf on this
alias window_size = 2048
alias hop_size = window_size // 2

struct PaulStretchWindow[window_size: Int](FFTProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)

    fn get_messages(mut self) -> None:
        pass

    # the stereo fft process has to be formatted this way
    fn next_frame[num_chans: Int = 2](mut self, mut mags: List[SIMD[DType.float64, num_chans]], mut phases: List[SIMD[DType.float64, num_chans]]) -> None:
        # you have to explicitly address both channels of mags and phases
        for ref p in phases:
            p = SIMD[DType.float64, num_chans](random_float64(0.0, 2.0 * 3.141592653589793), random_float64(0.0, 2.0 * 3.141592653589793))

# User's Synth
struct PaulStretch(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var saw: LFSaw
    var paul_stretch: FFTProcess[PaulStretchWindow[window_size],window_size,hop_size,WindowTypes.sine,WindowTypes.sine]
    var m: Messenger
    var dur_mult: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.buffer = Buffer("resources/Shiverer.wav")
        self.saw = LFSaw(self.world_ptr)

        self.paul_stretch = FFTProcess[
                PaulStretchWindow[window_size],
                window_size,
                hop_size,
                WindowTypes.sine,
                WindowTypes.sine
            ](self.world_ptr,process=PaulStretchWindow[window_size](self.world_ptr))

        self.m = Messenger(world_ptr)
        self.dur_mult = 20.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        phase = self.saw.next(speed)*0.5 + 0.5
        o = self.paul_stretch.next_from_buffer[2](self.buffer, phase, 0)
        return o

