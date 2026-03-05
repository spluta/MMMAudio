
from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
comptime num_osc = 4

struct TestLFNoise(Movable, Copyable):
    var world: World
    var noise: LFNoise[num_osc, Interp.none]
    var synth: Osc[num_osc]
    var interp: Int

    fn __init__(out self, world: World):
        self.world = world
        self.noise = LFNoise[num_osc, Interp.none](self.world)
        self.synth = Osc[num_osc](self.world)
        self.interp = 0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()
        freq = self.noise.next(SIMD[DType.float64, num_osc](0.5,0.4,0.3,0.2)) * 200.0 + 300.0
        sample = self.synth.next(freq)  # Get the next sample from the synth
        return splay(sample, self.world) * 0.2  # Get the next sample from the synth

    fn get_msgs(mut self: Self):
        # Get messages from the world


        