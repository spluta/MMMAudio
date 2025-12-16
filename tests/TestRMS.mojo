from mmm_src.MMMWorld import *
from mmm_dsp.BufferedProcess import BufferedProcess, BufferedProcessable
from mmm_utils.Messenger import Messenger
from mmm_utils.Print import Print
from mmm_utils.Windows import WindowTypes
from mmm_dsp.PlayBuf import PlayBuf
from mmm_utils.functions import select
from mmm_utils.functions import dbamp
from mmm_dsp.RMS import RMS

# User's Synth
struct TestRMS(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: PlayBuf
    # samplerate of 48000 50 ms for the RMS = 2400 samples
    var rms: BufferedProcess[RMS,2400,2400]
    var m: Messenger
    var printer: Print
    var vol: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world) 
        rms = RMS(self.world)
        self.rms = BufferedProcess[RMS,2400,2400](self.world,process=rms^)
        self.m = Messenger(world)
        self.printer = Print(world)
        self.vol = 0.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.vol,"vol")
        
        i = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        
        i *= dbamp(self.vol)
        
        rms = self.rms.next(i)
        self.printer.next(rms, "RMS: ")
        return SIMD[DType.float64,2](i,i)

