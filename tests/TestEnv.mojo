"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_utils.Messengers import Messenger

from mmm_dsp.Osc import *
from mmm_dsp.Env import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestEnv(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var env_params: EnvParams
    var env: Env
    var synth: Osc
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.env_params = EnvParams(List[Float64](-1, 1.0, -0.5, 0.5, -1.0), List[Float64](1, 1, 0.5, 4), List[Float64](2), True, 0.1)
        self.env = Env(self.world_ptr)
        self.synth = Osc(self.world_ptr)
        self.messenger = Messenger(world_ptr)
        

    fn next(mut self) -> SIMD[DType.float64, 2]:
        mul =self.messenger.get_val("mul", 1.0)
        if self.messenger.triggered("mul"):
            for ref val in self.env_params.values:
                val *= mul

        self.env_params.time_warp = linexp(self.world_ptr[0].mouse_x, 0.0, 1.0, 0.1, 10.0)
        self.env_params.curves[0] = linlin(self.world_ptr[0].mouse_y, 0.0, 1.0, -16.0, 16.0)
        self.world_ptr[0].print(self.env_params.curves[0])
        # self.env_params.curves[0] = self.messenger.get_val("curve", 1)
        env = self.env.next(self.env_params)
        sample = self.synth.next(500)
        return env * sample * 0.1



        