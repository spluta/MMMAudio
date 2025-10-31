"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_utils.functions import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestOsc[N: Int = 2](Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc[N](world_ptr)

    fn next(mut self) -> SIMD[DType.float64, self.N]:
        sample = self.osc.next()
        return sample * 0.1


        