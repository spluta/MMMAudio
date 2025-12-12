from mmm_src.MMMWorld import *
from mmm_dsp.BufferedProcess import BufferedProcess, BufferedProcessable
from mmm_utils.Messenger import Messenger
from mmm_utils.Print import Print
from mmm_utils.Windows import WindowType
from mmm_dsp.PlayBuf import PlayBuf
from mmm_utils.functions import select
from mmm_utils.functions import dbamp
from mmm_dsp.FFT import RealFFT
from complex import ComplexFloat64

alias window_size = 4096
alias hop_size = window_size // 2

# This corresponds to the user defined BufferedProcess.
struct FFTLowPass[window_size: Int](BufferedProcessable):
    var w: UnsafePointer[MMMWorld]
    var m: Messenger
    var bin: Int64
    var fft: RealFFT[window_size]
    # var complex: List[ComplexFloat64]
    var mags: List[Float64]
    var phases: List[Float64]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.bin = (window_size // 2) + 1
        self.m = Messenger(w)
        self.fft = RealFFT[window_size]()
        # self.complex = List[ComplexFloat64](length=(window_size // 2) + 1, fill=ComplexFloat64(0.0,0.0))
        self.mags = List[Float64](length=(window_size // 2) + 1, fill=0.0)
        self.phases = List[Float64](length=(window_size // 2) + 1, fill=0.0)

    fn get_messages(mut self) -> None:
        self.m.update(self.bin,"bin")

    fn next_window(mut self, mut input: List[Float64]) -> None:
        # self.fft.fft(input,self.complex)
        self.fft.fft(input,self.mags,self.phases)
        for i in range(self.bin,(window_size // 2) + 1):
            self.mags[i] *= 0.0
        # self.fft.ifft(self.complex,input)
        self.fft.ifft(self.mags,self.phases,input)

# User's Synth
struct TestBufferedProcessFFT(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: PlayBuf
    var fftlowpass: BufferedProcess[FFTLowPass[window_size],window_size,hop_size,WindowType.sine,WindowType.sine]
    var m: Messenger
    var ps: List[Print]
    var which: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.buffer = SoundFile.load("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.w) 
        self.fftlowpass = BufferedProcess[FFTLowPass[window_size],window_size,hop_size,WindowType.sine,WindowType.sine](self.w,process=FFTLowPass[window_size](self.w))
        self.m = Messenger(w)
        self.ps = List[Print](length=2,fill=Print(w))
        self.which = 0

    fn next(mut self) -> SIMD[DType.float64,2]:
        i = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        o = self.fftlowpass.next(i)
        return SIMD[DType.float64,2](o,o)

