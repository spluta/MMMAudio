"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import *
from mmm_utils.functions import *

from mmm_utils.Messenger import Messenger

from mmm_dsp.Osc import *
from mmm_dsp.Env import ASREnv


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestASR(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var env: ASREnv
    var synth: Osc
    var messenger: Messenger
    var curves: SIMD[DType.float64, 2]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.env = ASREnv(self.w)
        self.synth = Osc(self.w)
        self.messenger = Messenger(w)
        self.curves = SIMD[DType.float64, 2](1.0, 1.0)
        

    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.w[].top_of_block:
            curves = self.messenger.get_list("curves")
            for i in range(min(2, len(curves))):
                self.curves[i] = curves[i]
        # [TODO] it would be great to get "gate" from Python as a boolean
        gate = self.messenger.get_val("gate", 0.0) > 0.5

        env = self.env.next(self.w[].mouse_x, 1, self.w[].mouse_y, gate, self.curves)
        sample = self.synth.next(200)
        return env * sample * 0.1



        