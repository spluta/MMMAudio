
from mmm_audio import *

struct TestHilbert(Movable, Copyable):
    var world: World
    var hilbert: Hilbert[2048,1024]
    var sine: Osc[]
    var m: Messenger
    var freq: MFloat[]
    var radians: MFloat[]

    fn __init__(out self, world: World):
        self.world = world
        self.hilbert = Hilbert[2048,1024](self.world)
        self.sine = Osc(self.world)
        self.m = Messenger(self.world)
        self.freq = 440.0
        self.radians = pi/2.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.freq, "freq")
        self.m.update(self.radians, "radians")
        s = self.sine.next(self.freq)
        o = self.hilbert.next(s, self.radians)
        return SIMD[DType.float64,2](o[0],o[1]) * 0.1

