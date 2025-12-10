"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *


from mmm_dsp.Osc import Osc
from mmm_utils.functions import *
from algorithm import parallelize


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestOsc[N: Int = 1, num: Int = 6000](Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: List[Osc]
    var freqs: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = [Osc(world_ptr) for _ in range(self.num)]
        self.freqs = [random_float64() * 2000 + 100 for _ in range(self.num)]

    fn next(mut self) -> Float64:
        sample = 0.0

        for i in range(self.num):
            sample += self.osc[i].next(self.freqs[i]) 
        return sample * (0.2 / self.num)
