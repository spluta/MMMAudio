"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_utils.Messengers import Messenger

from mmm_dsp.Osc import *
from mmm_dsp.Env import Env


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestASR(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var env: Env
    var synth: Osc
    var messenger: Messenger
    var curves: SIMD[DType.float64, 2]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.env = Env(self.world_ptr)
        self.synth = Osc(self.world_ptr)
        self.messenger = Messenger(world_ptr)
        self.curves = SIMD[DType.float64, 2](1.0, 1.0)
        

    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.world_ptr[0].top_of_block:
            curves = self.messenger.get_list("curves")
            for i in range(min(2, len(curves))):
                self.curves[i] = curves[i]
        gate = self.messenger.get_val("gate", 0.0)

        env = self.env.asr(self.world_ptr[0].mouse_x, 1, self.world_ptr[0].mouse_y, gate, self.curves)
        sample = self.synth.next(200)
        return env * sample * 0.1



        