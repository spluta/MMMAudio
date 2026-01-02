

from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestHardClipADAA[N: Int = 2](Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var osc: Osc
    var lag: Lag
    var clip: SoftClipAD[1, 1]
    var overdrive: TanhAD[N]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.osc = Osc(world)
        self.clip = SoftClipAD[1, 1](world)
        self.overdrive = TanhAD[N]()
        self.lag = Lag(world)

    fn next(mut self) -> SIMD[DType.float64, self.N]:
        sample = self.osc.next(self.world[].mouse_y * 40.0 + 20)  # Get the next white noise sample
        gain = self.lag.next(self.world[].mouse_x * 20.0)

        sample2 = self.clip.next1(sample*gain) 
        # sample = self.overdrive.next1(sample*gain)
        return SIMD[DType.float64, self.N](sample, sample2)


        