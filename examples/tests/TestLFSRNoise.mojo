from mmm_audio import *

struct TestLFSRNoise(Movable, Copyable):
    var world: World
    var lfsr: LFSRNoise[1]
    var messenger: Messenger
    var freq: Float64
    var gain: Float64
    var width: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.lfsr = LFSRNoise[1](world)
        self.messenger = Messenger(self.world)
        self.freq = 1000.0
        self.gain = 0.2
        self.width = 15.0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq, "freq")
        self.messenger.update(self.gain, "gain")
        self.messenger.update(self.width, "width")

        var sample = self.lfsr.next(self.freq, SIMD[DType.uint32, 1](Int(self.width)), False)
        return SIMD[DType.float64, 2](sample, sample) * self.gain