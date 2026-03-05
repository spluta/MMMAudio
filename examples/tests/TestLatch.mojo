
from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestLatch(Movable, Copyable):
    var world: World
    var osc: SinOsc[]
    var lfo: SinOsc[]
    var latch: Latch[] 
    var dusty: Dust[]
    var messenger: Messenger

    fn __init__(out self, world: World):
        self.world = world
        self.osc = SinOsc(self.world)
        self.lfo = SinOsc(self.world)
        self.latch = Latch()
        self.dusty = Dust(self.world)
        self.messenger = Messenger(self.world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq = self.lfo.next(0.1) * 200 + 300
        freq = self.latch.next(freq,self.dusty.next(0.5) > 0.0)
        sample = self.osc.next(freq)  # Get the next sample from the synth
        return sample * 0.2  # Get the next sample from the synth