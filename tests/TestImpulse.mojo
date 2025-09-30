"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestImpulse(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Impulse[2]
    var trig: SIMD[DType.float64, 2]
    var freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Impulse[2](self.world_ptr)
        self.trig = SIMD[DType.float64, 2](1.0)
        self.freq = 0.5

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()
        sample = self.synth.next(self.freq, self.trig)  # Get the next sample from the synth
        return sample * 0.2  # Get the next sample from the synth

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("trig")
        if msg:
            self.trig = SIMD[DType.float64, 2](msg.value()[0], msg.value()[1])
        else:
            self.trig = 0.0
        msg = self.world_ptr[0].get_msg("freq")
        if msg:
            self.freq = msg.value()[0]