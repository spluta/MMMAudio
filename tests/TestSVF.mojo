"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messenger import Messenger
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *

struct TestSVF(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var osc: LFSaw[1,2]
    var filts: List[SVF]
    var messenger: Messenger
    var freq: Float64
    var cutoff: Float64
    var res: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.osc = LFSaw[1,2](w)
        self.messenger = Messenger(w)
        self.filts = List[SVF](capacity=2)
        self.freq = 440
        self.cutoff = 1000.0
        self.res = 1.0
        for i in range(2):
            self.filts[i] = SVF(w)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq,"freq")
        sample = self.osc.next(self.freq) 
        outs = SIMD[DType.float64, 2](0.0,0.0)
        self.messenger.update(self.cutoff,"cutoff")
        self.messenger.update(self.res,"res")
        outs[0] = self.filts[0].lpf(sample, self.cutoff, self.res)
        outs[1] = self.filts[1].hpf(sample, self.cutoff, self.res)
        return outs * 0.2