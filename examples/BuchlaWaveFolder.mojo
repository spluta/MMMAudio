from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_dsp.Filters import Lag
from mmm_utils.Messenger import Messenger
from mmm_dsp.Env import ASREnv
from mmm_dsp.Distortion import buchla_wavefolder

struct BuchlaWaveFolder(Representable, Movable, Copyable):
    var world: UnsafePointer[MMMWorld]  
    var osc: Osc[2]
    var lag: Lag
    var m: Messenger


    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        # for efficiency we set the interpolation and oversampling in the constructor
        self.osc = Osc[2](self.world)
        self.lag = Lag(self.world, 0.1)
        self.m = Messenger(self.world)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        amp = self.lag.next(self.world[].mouse_x * 39.0) + 1

        sample = self.osc.next_interp(40)
        sample = buchla_wavefolder(sample, amp)

        return sample
