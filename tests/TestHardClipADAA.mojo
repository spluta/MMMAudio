"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *


from mmm_dsp.Osc import Osc
from mmm_dsp.Distortion import HardClipAD, TanhAD
from mmm_utils.functions import *
from mmm_dsp.Filters import Lag


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestHardClipADAA[N: Int = 2](Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var osc: Osc[N]
    var lag: Lag[N]
    var clip: HardClipAD[N, 2]
    var overdrive: TanhAD[N]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.osc = Osc[N](world)
        self.clip = HardClipAD[N, 2](world)
        self.overdrive = TanhAD[N]()
        self.lag = Lag[N](world)

    fn next(mut self) -> SIMD[DType.float64, self.N]:
        sample = self.osc.next(40)  # Get the next white noise sample
        gain = self.lag.next(self.world[].mouse_x * 20.0)
        sample = self.clip.next1(sample*gain) 
        # sample = self.overdrive.next1(sample*gain)
        return sample * 0.5


        