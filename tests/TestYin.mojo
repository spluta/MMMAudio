"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Analysis import Pitch
from mmm_dsp.Osc import Osc
from mmm_utils.Messengers import *

struct TestYin(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var pitch: Pitch[window_size=1024, hop_size=512, min_freq=60.0, max_freq=5000.0]
    var freq: Float64
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(world_ptr)
        self.pitch = Pitch[window_size=1024, hop_size=512, min_freq=60.0, max_freq=5000.0](self.world_ptr)
        self.freq = 440.0
        self.m = Messenger(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.m.update(self.freq,"freq")
        sample = self.osc.next(self.freq)
        (frequency, confidence) = self.pitch.next(sample)
        self.world_ptr[].print("Frequency: ", frequency, " Hz, Confidence: ", confidence)
        out = SIMD[DType.float64, 2](sample,sample)
        return out
