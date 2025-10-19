"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_dsp.Filters import Lag

struct VariableOsc(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    # for efficiency we set the interpolation and oversampling in the constructor
    # so here we have sinc interpolation with 2x oversampling
    # var osc: Osc[1,2,1]
    # var lag: Lag[1]
    var osc: Osc[2,2,1]
    var lag: Lag[0.1, 2]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        # for efficiency we set the interpolation and oversampling in the constructor
        self.osc = Osc[2,2,1](self.world_ptr)
        self.lag = Lag[0.1, 2](self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        # freq = self.world_ptr[0].mouse_y
        freq = SIMD[DType.float64, 2](1-self.world_ptr[0].mouse_y, self.world_ptr[0].mouse_y)
        freq = self.lag.next(freq)
        freq = linexp(freq, 0.0, 1.0, 100, 10000)

        # by defualt, next_interp will interpolate between the four default waveforms - sin, tri, square, saw

        # osc_frac = self.world_ptr[0].mouse_x
        osc_frac = SIMD[DType.float64, 2](1-self.world_ptr[0].mouse_x, self.world_ptr[0].mouse_x)
        sample = self.osc.next_interp(freq, osc_frac = osc_frac)

        return sample * 0.1
