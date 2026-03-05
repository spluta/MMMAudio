from mmm_audio import *

struct TestBiquad(Movable, Copyable):
    var world: World
    var noise: WhiteNoise[1]
    var filts: List[Biquad[1]]
    var messenger: Messenger
    var cutoff: Float64
    var q: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.noise = WhiteNoise[1]()
        self.messenger = Messenger(self.world)
        self.filts = List[Biquad[1]](capacity=2)
        self.cutoff = 1000.0
        self.q = 1.0
        for i in range(2):
            self.filts.append(Biquad[1](self.world))

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.cutoff, "cutoff")
        self.messenger.update(self.q, "q")
        var sample = self.noise.next()
        var outs = SIMD[DType.float64, 2](0.0, 0.0)
        outs[0] = self.filts[0].lpf(sample, SIMD[DType.float64, 1](self.cutoff), SIMD[DType.float64, 1](self.q))[0]
        outs[1] = self.filts[1].hpf(sample, SIMD[DType.float64, 1](self.cutoff), SIMD[DType.float64, 1](self.q))[0]
        return outs * 0.2