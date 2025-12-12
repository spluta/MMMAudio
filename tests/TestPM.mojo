"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import *
from mmm_utils.Messenger import Messenger
from mmm_utils.functions import *


from mmm_dsp.Osc import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestPM(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var mod: Osc
    var carrier: Osc
    var lag: Lag[1]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.mod = Osc(self.w)
        self.carrier = Osc(self.w)
        self.lag = Lag[1](self.w, 0.2)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq = linexp(self.w[].mouse_x, 0.0, 1.0, 100.0, 1000.0)
        mod_mul = linexp(self.w[].mouse_y, 0.0, 1.0, 0.0001, 32.0)
        mod_signal = self.mod.next(50)
        sample = self.carrier.next(100, mod_signal * self.lag.next(mod_mul))
        return sample * 0.1