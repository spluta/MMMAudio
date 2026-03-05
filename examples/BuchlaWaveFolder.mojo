from mmm_audio import *

struct BuchlaWaveFolder(Representable, Movable, Copyable):
    var world: World  
    var osc: Osc[2]
    var lag: Lag[1]
    var m: Messenger


    fn __init__(out self, world: World):
        self.world = world
        # for efficiency we set the interpolation and oversampling in the constructor
        self.osc = Osc[2](self.world)
        self.lag = Lag(self.world, 0.1)
        self.m = Messenger(self.world)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        amp = self.lag.next(self.world[].mouse_x * 39.0) + 1

        sample = self.osc.next_basic_waveforms(40)
        sample = buchla_wavefolder(sample, amp)

        return sample
