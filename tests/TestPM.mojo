"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestPM(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var mod: Osc
    var carrier: Osc
    var lag: Lag[1]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.mod = Osc(self.world_ptr)
        self.carrier = Osc(self.world_ptr)
        self.lag = Lag[1](self.world_ptr, 0.2)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq = linexp(self.world_ptr[0].mouse_x, 0.0, 1.0, 100.0, 1000.0)
        mod_mul = linexp(self.world_ptr[0].mouse_y, 0.0, 1.0, 0.0001, 32.0)
        mod_signal = self.mod.next(50)
        sample = self.carrier.next(100, mod_signal * self.lag.next(mod_mul))
        return sample * 0.1