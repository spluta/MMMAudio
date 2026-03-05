
from mmm_audio import *

comptime num_output_channels = 2
comptime num_osc = 1000
# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestSplay(Movable, Copyable):
    var world: World
    var osc: List[Osc[2]]
    var freqs: List[Float64]
    var mult: Float64
    var samples: List[SIMD[DType.float64, 2]]
    var splay: SplayN[num_output_channels]

    fn __init__(out self, world: World):
        self.world = world
        self.osc = [Osc[2](self.world) for _ in range(num_osc)]
        self.freqs = [random_float64() * 2000 + 100 for _ in range(num_osc)]
        self.mult = 0.2 / Float64(num_osc)
        self.samples = [SIMD[DType.float64, 2](0.0) for _ in range(num_osc)]
        self.splay = SplayN[num_channels = num_output_channels](self.world)

    fn next(mut self) -> SIMD[DType.float64, num_output_channels]:
        for i in range(num_osc):
             self.samples[i] = self.osc[i].next(self.freqs[i])

        sample2 = self.splay.next(self.samples)
        # sample2 = splay(self.samples, self.world)
        return sample2 * self.mult
