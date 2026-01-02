

from mmm_src.MMMWorld_Module import *
from mmm_utils.functions import *

from mmm_utils.Messenger_Module import Messenger

from mmm_dsp.Oscillators import *
from mmm_dsp.Env import ASREnv


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestASR(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var env: ASREnv
    var synth: Osc
    var messenger: Messenger
    var curves: SIMD[DType.float64, 2]
    var gate: Bool

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.env = ASREnv(self.world)
        self.synth = Osc(self.world)
        self.messenger = Messenger(self.world)
        self.curves = SIMD[DType.float64, 2](1.0, 1.0)
        self.gate = False

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.curves,"curves")
        self.messenger.update(self.gate,"gate")

        env = self.env.next(self.world[].mouse_x, 1, self.world[].mouse_y, self.gate, self.curves)
        sample = self.synth.next(200)
        return env * sample * 0.1



        