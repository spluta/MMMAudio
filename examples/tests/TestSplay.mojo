
from mmm_audio import *

comptime num_output_channels = 20
comptime num_osc = 1000
# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestSplay(Movable, Copyable):
    var world: World
    var osc: List[Osc[2]]
    var freqs: List[Float64]
    var mult: Float64
    # var samples: List[MFloat[2]]
    var samples: InlineArray[MFloat[2], num_osc]
    var splay: SplayN[num_output_channels]

    def __init__(out self, world: World):
        self.world = world
        self.osc = [Osc[2](self.world) for _ in range(num_osc)]
        self.freqs = [random_float64() * 2000 + 100 for _ in range(num_osc)]
        self.mult = 0.2 / Float64(num_osc)
        # self.samples = [MFloat[2](0.0) for _ in range(num_osc)]
        self.samples = InlineArray[MFloat[2], num_osc](0.0)
        self.splay = SplayN[num_channels = num_output_channels]()

    def next(mut self) -> MFloat[num_output_channels]:
        for i in range(num_osc):
             self.samples[i] = self.osc[i].next(self.freqs[i])

        sample2 = self.splay.next(self.samples)
        # sample2 = splay(self.samples, self.world)
        return sample2 * self.mult
