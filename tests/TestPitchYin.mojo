"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Analysis import PitchYIN
from mmm_dsp.Osc import Osc
from mmm_utils.Messengers import *


struct TestPitchYin(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var pitch_yin: PitchYIN[1024, 512, 50.0, 5000.0]
    var freq: Float64
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(world_ptr)
        self.pitch_yin = PitchYIN[1024, 512, 50.0, 5000.0](self.world_ptr)
        self.freq = 440.0
        self.m = Messenger(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.m.update(self.freq,"freq")
        sample = self.osc.next(self.freq)
        (pitch, confidence) = self.pitch_yin.next(sample)
        self.world_ptr[].print("Pitch: ", pitch, " Hz, Confidence: ", confidence)
        out = SIMD[DType.float64, 2](sample,sample)
        return out
