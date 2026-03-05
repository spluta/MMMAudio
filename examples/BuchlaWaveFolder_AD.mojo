from mmm_audio import *

struct BuchlaWaveFolder_AD(Representable, Movable, Copyable):
    var world: World  
    var osc: Osc[2]
    var lag: Lag[1]
    var b259: BuchlaWavefolder[2, 1]
    var m: Messenger


    fn __init__(out self, world: World):
        self.world = world
        # for efficiency we set the interpolation and oversampling in the constructor
        self.osc = Osc[2](world)
        self.lag = Lag(world, 0.1)
        self.b259 = BuchlaWavefolder[2, 1](world)
        self.m = Messenger(world)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        amp = self.lag.next(self.world[].mouse_x * 30.0) + 1

        freq = self.world[].mouse_y * 200 + 10

        sample = self.osc.next_basic_waveforms(freq)

        sample = self.b259.next(sample, amp)

        return sample * 0.5