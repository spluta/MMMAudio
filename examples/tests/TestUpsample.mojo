
from mmm_audio import *

comptime times_oversample = 16
struct TestUpsample(Movable, Copyable):
    var world: World
    var osc: Osc[]
    var upsampler: Upsampler[1, times_oversample]
    var messenger: Messenger

    fn __init__(out self, world: World):
        self.world = world
        self.osc = Osc(world)
        self.upsampler = Upsampler[1, times_oversample](world)
        self.messenger = Messenger(world)

    fn next(mut self) -> SIMD[DType.float64, 2]:

        sample = self.osc.next(self.world[].mouse_y * 200.0 + 20.0, osc_type = OscType.triangle)
        sample2 = 0.0
        for i in range(times_oversample):
            sample2 = self.upsampler.next(sample, i)

        return SIMD[DType.float64, 2](sample, sample2) * 0.2
