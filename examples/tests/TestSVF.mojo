
from mmm_audio import *

struct TestSVF(Movable, Copyable):
    var world: World
    var osc: LFSaw[]
    var filts: List[Biquad[]]
    var messenger: Messenger
    var freq: Float64
    var cutoff: Float64
    var res: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.osc = LFSaw(self.world)
        self.messenger = Messenger(self.world)
        self.filts = List[Biquad[]](capacity=2)
        self.freq = 440
        self.cutoff = 1000.0
        self.res = 1.0
        for i in range(2):
            self.filts[i] = Biquad(self.world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq,"freq")
        sample = self.osc.next(self.freq) 
        outs = SIMD[DType.float64, 2](0.0,0.0)
        self.cutoff = linexp(self.world[].mouse_x, 0.0, 1.0, 20.0, 20000.0)
        self.messenger.update(self.res,"res")
        outs[0] = self.filts[0].lpf(sample, self.cutoff, self.res)
        outs[1] = self.filts[1].hpf(sample, self.cutoff, self.res)
        return outs * 0.2