from mmm_src.MMMWorld import *
from mmm_utils.Messenger import Messenger
from mmm_utils.functions import *

from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct TestSelect(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var messenger: Messenger
    var vs: List[Float64]
    var printers: List[Print]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.messenger = Messenger(w)
        self.vs = List[Float64](capacity=8)
        self.printers = List[Print](capacity=2)
        for i in range(8):
            self.vs.append(i * 100)

        self.printers[0] = Print(w)
        self.printers[1] = Print(w)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.vs[0] = self.messenger.get_val("v0", 0.0)
        self.vs[1] = self.messenger.get_val("v1", 100.0)
        self.vs[2] = self.messenger.get_val("v2", 200.0)
        self.vs[3] = self.messenger.get_val("v3", 300.0)
        self.vs[4] = self.messenger.get_val("v4", 400.0)
        self.vs[5] = self.messenger.get_val("v5", 500.0)
        self.vs[6] = self.messenger.get_val("v6", 600.0)
        self.vs[7] = self.messenger.get_val("v7", 700.0)
        which = self.messenger.get_val("which", 0.0)
        val = select(which, self.vs)
        self.printers[0].next(val, "selected value in self.vs: ")

        val2 = select(which,[11.1,12.2,13.3,14.4,15.5,16.6,17.7,18.8])
        self.printers[1].next(val2, "selected value in [11..18]: ")

        return SIMD[DType.float64, 2](0.0, 0.0)