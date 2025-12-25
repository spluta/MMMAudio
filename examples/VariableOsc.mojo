"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import *
from mmm_utils.functions import *


from mmm_dsp.Osc import Osc
from mmm_dsp.Filters import Lag
from mmm_utils.Messenger import Messenger
from mmm_dsp.Env import ASREnv

struct VariableOsc(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]  
    # for efficiency we set the interpolation and oversampling in the constructor
    # so here we have sinc interpolation with 2x oversampling
    # var osc: Osc[1,2,1]
    # var lag: Lag[1]
    var osc: Osc[2,5,1]
    var lag: Lag[2]
    var m: Messenger
    var x: Float64
    var y: Float64
    var is_down: Bool
    var asr: ASREnv

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        # for efficiency we set the interpolation and oversampling in the constructor
        self.osc = Osc[2,5,1](self.w)
        self.lag = Lag[2](self.w, 0.1)
        self.m = Messenger(self.w)
        self.x = 0.0
        self.y = 0.0
        self.is_down = False
        self.asr = ASREnv(self.w)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.m.update(self.x, "x")
        self.m.update(self.y, "y")
        self.m.update(self.is_down, "mouse_down")

        env = self.asr.next(0.05, 1, 0.05, self.is_down)

        # freq = self.w[].mouse_y
        freq = SIMD[DType.float64, 2](1-self.y, self.y)
        freq = self.lag.next(freq)
        freq = linexp(freq, 0.0, 1.0, 100, 10000)

        # by defualt, next_interp will interpolate between the four default waveforms - sin, tri, square, saw

        # osc_frac = self.w[].mouse_x
        osc_frac = SIMD[DType.float64, 2](1-self.x, self.x)
        sample = self.osc.next_vwt(freq, osc_frac = osc_frac)

        return sample * 0.1 * env
