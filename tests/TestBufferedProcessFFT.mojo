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

# This corresponds to the user defined BufferedProcess.
struct FFTLowPass[window_size: Int = 1024](BufferedProcessable):
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
        for i in range(self.bin,(window_size // 2) + 1):
            self.mags[i] *= 0.0
        # self.fft.ifft(self.complex,input)
        self.fft.ifft(self.mags,self.phases,input)

# User's Synth
struct TestBufferedProcessFFT(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: PlayBuf
    var fftlowpass: BufferedProcess[FFTLowPass,1024,512,None,WindowTypes.hann]
    var m: Messenger
    var ps: List[Print]
    var which: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world_ptr) 
        self.fftlowpass = BufferedProcess[FFTLowPass[1024],1024,512,None,WindowTypes.hann](self.world_ptr,process=FFTLowPass(self.world_ptr))
        self.m = Messenger(world_ptr)
        self.ps = List[Print](length=2,fill=Print(world_ptr))
        self.which = 0

    fn next(mut self) -> SIMD[DType.float64,2]:
        i = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        o = self.fftlowpass.next(i)
        return SIMD[DType.float64,2](o,o)

