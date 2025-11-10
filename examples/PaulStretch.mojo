from mmm_src.MMMWorld import *
from mmm_dsp.BufferedProcess import BufferedProcess, BufferedProcessable
from mmm_utils.Messengers import Messenger
from mmm_utils.Print import Print
from mmm_utils.Windows import WindowTypes
from mmm_dsp.PlayBuf import PlayBuf
from mmm_utils.functions import select
from mmm_utils.functions import dbamp
from mmm_dsp.FFT import FFT
from complex import ComplexFloat64
from mmm_dsp.Osc import LFSaw
from random import random_float64

# this really should have a window size of 8192 or more, but the numpy FFT seems to barf on this
alias window_size = 1024
alias hop_size = window_size // 2

struct PaulStretchWindow[window_size: Int](BufferedProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var bin: Int64
    var fft: FFT[window_size]
    # var complex: List[ComplexFloat64]
    var mags: List[Float64]
    var phases: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.bin = (window_size // 2) + 1
        self.m = Messenger(world_ptr)
        self.fft = FFT[window_size]()
        # self.complex = List[ComplexFloat64](length=(window_size // 2) + 1, fill=ComplexFloat64(0.0,0.0))
        self.mags = List[Float64](length=(window_size // 2) + 1, fill=0.0)
        self.phases = List[Float64](length=(window_size // 2) + 1, fill=0.0)

    fn get_messages(mut self) -> None:
        self.m.update(self.bin,"bin")

    fn next_window(mut self, mut input: List[Float64]) -> None:
        # self.fft.fft(input,self.complex)
        self.fft.fft(input,self.mags,self.phases)
        for i in range(0,(window_size // 2) + 1):
            self.phases[i] = random_float64(0.0, 2.0 * 3.141592653589793)
        self.fft.ifft(self.mags,self.phases,input)

# User's Synth
struct PaulStretch(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var saw: LFSaw
    var paul_stretch: BufferedProcess[PaulStretchWindow[window_size],window_size,hop_size,WindowTypes.sine,WindowTypes.sine]
    var paul_stretch2: BufferedProcess[PaulStretchWindow[window_size],window_size,hop_size,WindowTypes.sine,WindowTypes.sine]
    var m: Messenger
    var dur_mult: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.buffer = Buffer("resources/Shiverer.wav")
        self.saw = LFSaw(self.world_ptr)
        self.paul_stretch = BufferedProcess[PaulStretchWindow[window_size],window_size,hop_size,WindowTypes.sine,WindowTypes.sine](self.world_ptr,process=PaulStretchWindow[window_size](self.world_ptr))
        self.paul_stretch2 = BufferedProcess[PaulStretchWindow[window_size],window_size,hop_size,WindowTypes.sine,WindowTypes.sine](self.world_ptr,process=PaulStretchWindow[window_size](self.world_ptr))
        self.m = Messenger(world_ptr)
        self.dur_mult = 100.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        phase = self.saw.next(speed)*0.5 + 0.5
        o = self.paul_stretch.next_from_buffer(self.buffer, phase, 0) #channel 0
        p = self.paul_stretch2.next_from_buffer(self.buffer, phase, 1) #channel 1
        return SIMD[DType.float64,2](o,p)

