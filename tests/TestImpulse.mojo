"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
from mmm_utils.functions import *


from mmm_dsp.Osc import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestImpulse(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Impulse[2]
    var trig: SIMD[DType.bool, 2]
    var freq: Float64
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Impulse[2](self.world_ptr)
        self.trig = SIMD[DType.bool, 2](fill=True)
        self.freq = 0.5
        self.messenger = Messenger(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.world_ptr[0].top_of_block:
            if self.messenger.triggered("trig"):
                temp = self.messenger.get_list("trig")
                for i in range(min(2, len(temp))):
                    self.trig[i] = temp[i] > 0.0
            else:
                self.trig = SIMD[DType.bool, 2](fill = False)

            self.freq = self.messenger.get_val("freq", 0.5)

        sample = self.synth.next(self.freq, self.trig)  # Get the next sample from the synth
        return sample * 0.2  # Get the next sample from the synth