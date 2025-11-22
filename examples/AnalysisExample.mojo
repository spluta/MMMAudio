"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Analysis import Pitch, SpectralCentroid, Units, YIN, RMS
from mmm_dsp.Osc import *
from mmm_utils.Messengers import *
from mmm_dsp.BufferedProcess import *
from mmm_dsp.FFT import *
from mmm_dsp.PlayBuf import *

struct CustomAnalysis[window_size: Int = 1024](BufferedProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var centroid: Float64
    var rms: Float64
    var pitch: Float64
    var pitch_conf: Float64
    var sr: Float64
    var yin: YIN[window_size, 50, 5000, units=Units.hz]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.sr = self.world_ptr[].sample_rate
        self.centroid = 0.0
        self.pitch = 0.0
        self.pitch_conf = 0.0
        self.rms = 0.0
        self.yin = YIN[window_size, 50, 5000, units=Units.hz](world_ptr)

    fn next_window(mut self, mut frame: List[Float64]):
        self.yin.next_window(frame)
        self.pitch = self.yin.pitch
        self.pitch_conf = self.yin.confidence
        self.rms = RMS.from_window(frame)
        # YIN has to do a special FFT internally no matter what, 
        # so we'll just use the "raw" mags it computes
        # for spectral centroid. It is an FFT with double the frequency resolution
        # (i.e., it's higher resolution, just "interpolated" FFT mags). But it will work just fine here.
        self.centroid = SpectralCentroid[unit=Units.hz].from_mags(self.yin.fft.mags, self.world_ptr[].sample_rate)

struct AnalysisExample(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc[2]
    var buffer: Buffer
    var playBuf: PlayBuf
    var freq: Float64
    var analyzer: BufferedInput[CustomAnalysis[1024],1024,512]
    var m: Messenger
    var which: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc[2](world_ptr)
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world_ptr)
        self.analyzer = BufferedInput[CustomAnalysis[1024],1024,512](world_ptr, CustomAnalysis[1024](world_ptr))
        self.freq = 440.0
        self.m = Messenger(world_ptr)
        self.which = 0.0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        
        self.m.update(self.freq,"freq")
        self.m.update(self.which,"which")

        oscs = self.osc.next(self.freq,0,False,[OscType.sine, OscType.saw])
        flute = self.playBuf.next(self.buffer,0,1.0,True)

        sig = select(self.which,[oscs[0], oscs[1], flute])
        
        # do the analysis
        self.analyzer.next(sig)

        # get the results
        (frequency, confidence) = (self.analyzer.process.pitch, self.analyzer.process.pitch_conf)
        rms = self.analyzer.process.rms
        centroid = self.analyzer.process.centroid
        
        # print the results
        self.world_ptr[].print("Pitch: ", frequency, " \tHz, Confidence: ", confidence, ", \tRMS: ", rms, ", \tCentroid: ", centroid)
        
        out = SIMD[DType.float64, 2](sig,sig)
        return out
