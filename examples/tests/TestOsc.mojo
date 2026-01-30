
from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestOsc[N: Int = 1, num: Int = 8000](Movable, Copyable):
    var world: World
    var osc: List[Osc]
    var freqs: List[Float64]

    fn __init__(out self, world: World):
        self.world = world
        self.osc = [Osc(self.world) for _ in range(self.num)]
        self.freqs = [random_float64() * 2000 + 100 for _ in range(self.num)]

    fn next(mut self) -> Float64:
        sample = 0.0

        for i in range(self.num):
            sample += self.osc[i].next(self.freqs[i]) 
        return sample * (0.2 / self.num)
