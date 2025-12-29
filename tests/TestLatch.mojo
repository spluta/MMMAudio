"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import *
from mmm_utils.Messenger import Messenger
from mmm_utils.functions import *

from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestLatch(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var osc: SinOsc
    var lfo: SinOsc
    var latch: Latch 
    var dusty: Dust
    var messenger: Messenger

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.osc = SinOsc(self.world)
        self.lfo = SinOsc(self.world)
        self.latch = Latch(self.world)
        self.dusty = Dust(self.world)
        self.messenger = Messenger(self.world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq = self.lfo.next(0.1) * 200 + 300
        freq = self.latch.next(freq,self.dusty.next(4) > 0.0)
        sample = self.osc.next(freq)  # Get the next sample from the synth
        return sample * 0.2  # Get the next sample from the synth