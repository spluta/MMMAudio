

from mmm_src.MMMWorld_Module import *
from mmm_utils.Messenger_Module import Messenger
from mmm_utils.functions import *


from mmm_dsp.Oscillators import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestPM(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var mod: Osc
    var carrier: Osc
    var lag: Lag[1]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.mod = Osc(self.world)
        self.carrier = Osc(self.world)
        self.lag = Lag[1](self.world, 0.2)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq = linexp(self.world[].mouse_x, 0.0, 1.0, 100.0, 1000.0)
        mod_mul = linexp(self.world[].mouse_y, 0.0, 1.0, 0.0001, 32.0)
        mod_signal = self.mod.next(50)
        sample = self.carrier.next(100, mod_signal * self.lag.next(mod_mul))
        return sample * 0.1