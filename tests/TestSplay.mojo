"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_utils.functions import *
from algorithm import parallelize
from mmm_dsp.Pan import splay, Splay, splay_gpu

alias num_output_channels = 2
# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestSplay[num: Int = 1000](Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var osc: List[Osc]
    var freqs: List[Float64]
    var mult: Float64
    var samples: List[Float64]
    var splay: Splay[num_output_channels]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.osc = [Osc(world) for _ in range(self.num)]
        self.freqs = [random_float64() * 2000 + 100 for _ in range(self.num)]
        self.mult = 0.2 / Float64(self.num)
        self.samples = [0.0 for _ in range(self.num)]
        self.splay = Splay[num_output_channels](world)

    fn next(mut self) -> SIMD[DType.float64, num_output_channels]:
        for i in range(self.num):
             self.samples[i] = self.osc[i].next(self.freqs[i]) 

        # sample2 = self.splay.next(self.samples)
        sample2 = splay(self.samples, self.world)
        return sample2 * self.mult
