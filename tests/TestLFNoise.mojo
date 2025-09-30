"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import *
from mmm_dsp.Pan import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestLFNoise[num_osc: Int = 4](Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var noise: LFNoise[num_osc, 1]
    var synth: Osc[num_osc]
    var interp: Int64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.noise = LFNoise[num_osc, 1](self.world_ptr)
        self.synth = Osc[num_osc](self.world_ptr)
        self.interp = 0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()
        freq = self.noise.next(SIMD[DType.float64, num_osc](0.5,0.4,0.3,0.2)) * 200.0 + 300.0
        sample = self.synth.next(freq)  # Get the next sample from the synth
        return splay(sample) * 0.2  # Get the next sample from the synth

    fn get_msgs(mut self: Self):
        # Get messages from the world


        