"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Noise import WhiteNoise
from mmm_dsp.Filters import OnePole
from mmm_utils.functions import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestOnePole[N: Int = 2](Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var noise: WhiteNoise[N]
    var filt: OnePole[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.noise = WhiteNoise[N]()
        self.filt = OnePole[N]()

    fn next(mut self) -> SIMD[DType.float64, self.N]:
        sample = self.noise.next()  # Get the next white noise sample
        self.world_ptr[0].print(sample)  # Print the sample to the console
        coef = SIMD[DType.float64, self.N](self.world_ptr[0].mouse_x, 1-self.world_ptr[0].mouse_x)  # Coefficient based on mouse X position
        sample = self.filt.next(sample, coef)  # Get the next sample from the filter
        return sample * 0.1


        