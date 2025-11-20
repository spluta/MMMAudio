"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Analysis import Pitch, SpectralCentroid, Units, YIN, RMS
from mmm_dsp.Osc import Osc
from mmm_utils.Messengers import *
from mmm_dsp.BufferedProcess import *
from mmm_dsp.FFT import *


struct CustomAnalysis[window_size: Int = 1024](BufferedProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var centroid: Float64
    var fft: FFT[window_size]
    var mags: List[Float64]
    var phases: List[Float64]
    var rms: Float64
    var pitch: Float64
    var pitch_conf: Float64
    var sr: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.sr = self.world_ptr[].sample_rate
        self.centroid = 0.0
        self.pitch = 0.0
        self.pitch_conf = 0.0
        self.fft = FFT[window_size]()
        self.mags = List[Float64](window_size // 2 + 1, 0.0)
        self.phases = List[Float64](window_size // 2 + 1, 0.0)
        self.rms = 0.0

    fn next_window(mut self, mut frame: List[Float64]):
        (self.pitch, self.pitch_conf) = YIN.from_window(frame, self.sr)
        self.rms = RMS.from_window(frame)
        self.fft.fft(frame,self.mags,self.phases)
        self.centroid = SpectralCentroid.from_mags(self.mags, self.sr)

struct TestAnalysis(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var freq: Float64
    var analyzer: BufferedProcess[CustomAnalysis[1024],1024,512,WindowTypes.hann]
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(world_ptr)
        self.analyzer = BufferedProcess[CustomAnalysis[1024],1024,512,WindowTypes.hann](world_ptr, CustomAnalysis[1024](world_ptr))
        self.freq = 440.0
        self.m = Messenger(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.m.update(self.freq,"freq")
        sample = self.osc.next(self.freq)
        
        _ = self.analyzer.next(sample)

        (frequency, confidence) = (self.analyzer.process.pitch, self.analyzer.process.pitch_conf)
        rms = self.analyzer.process.rms
        centroid = self.analyzer.process.centroid
        
        self.world_ptr[].print("Frequency: ", frequency, " Hz, Confidence: ", confidence, ", RMS: ", rms, ", Centroid: ", centroid, " Hz\n")
        
        out = SIMD[DType.float64, 2](sample,sample)
        return out
