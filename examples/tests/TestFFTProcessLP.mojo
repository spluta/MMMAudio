
from mmm_audio import *
from random import random

# User defined struct that implements FFTProcessable
struct FFTLowPass[window_size: Int = 1024](FFTProcessable):
    var lpbin: Int

    fn __init__(out self, world: World):
        self.lpbin = 20

    fn next_frame(mut self, mut magnitudes: List[Float64], mut phases: List[Float64]) -> None:
        for i in range(self.lpbin,(self.window_size // 2) + 1):
            magnitudes[i] = 0.0

# User's Main Synth
struct TestFFTProcess(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var playBuf: Play
    var fftlp: FFTProcess[FFTLowPass[1024]]

    fn __init__(out self, world: World):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world) 
        self.fftlp = FFTProcess[FFTLowPass[1024]](self.world, process=FFTLowPass[1024](self.world), window_size=1024, hop_size=512)

    fn next(mut self) -> SIMD[DType.float64,2]:

        input = self.playBuf.next(self.buffer)
        out = self.fftlp.next(input)
        return SIMD[DType.float64,2](out,out)

