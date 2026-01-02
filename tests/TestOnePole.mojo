

from mmm_src.MMMWorld_Module import *
from mmm_utils.functions import *


from mmm_dsp.Noise import WhiteNoise
from mmm_dsp.Filters import OnePole
from mmm_utils.functions import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestOnePole[N: Int = 2](Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var noise: WhiteNoise[N]
    var filt: OnePole[N]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.noise = WhiteNoise[N]()
        self.filt = OnePole[N]()

    fn next(mut self) -> SIMD[DType.float64, self.N]:
        sample = self.noise.next()  # Get the next white noise sample
        self.world[].print(sample)  # Print the sample to the console
        coef = SIMD[DType.float64, self.N](self.world[].mouse_x, 1-self.world[].mouse_x)  # Coefficient based on mouse X position
        sample = self.filt.next(sample, coef)  # Get the next sample from the filter
        return sample * 0.1


        