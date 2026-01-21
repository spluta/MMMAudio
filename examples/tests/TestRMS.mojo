
from mmm_audio import *

# User's Synth
struct TestRMS(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: Play
    # samplerate of 48000 50 ms for the RMS = 2400 samples
    var bi: BufferedInput[RMS,2400,2400]
    var m: Messenger
    var printer: Print
    var vol: Float64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world) 
        rms = RMS()
        self.bi = BufferedInput[RMS,2400,2400](self.world,process=rms^)
        self.m = Messenger(self.world)
        self.printer = Print(self.world)
        self.vol = 0.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.vol,"vol")
        
        i = self.playBuf.next(self.buffer, 1.0, True)  # Read samples from the buffer
        
        i *= dbamp(self.vol)
        
        self.bi.next(i)
        analysis_vol = ampdb(self.bi.process.rms)
        self.printer.next(analysis_vol, "RMS dB")
        return SIMD[DType.float64,2](i,i)

