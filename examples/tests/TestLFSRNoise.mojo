from mmm_audio import *

struct TestLFSRNoise(Movable, Copyable):
    var world: World
    var lfsr: LFSRNoise[2]
    var messenger: Messenger
    var freq: MFloat[2]
    var gain: MFloat[2]
    var width1: Int
    var width2: Int

    fn __init__(out self, world: World):
        self.world = world
        self.lfsr = LFSRNoise[2](world)
        self.messenger = Messenger(self.world)
        self.freq = MFloat[2](1000.0, 1010.0)
        self.gain = MFloat[2](0.2, 0.3)
        self.width1 = 15
        self.width2 = 7

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq[0], "freq1")
        self.messenger.update(self.freq[1], "freq2")
        self.messenger.update(self.gain[0], "gain1")
        self.messenger.update(self.gain[1], "gain2")
        self.messenger.update(self.width1, "width1")
        self.messenger.update(self.width2, "width2")

        var sample = self.lfsr.next(self.freq, MInt[2](self.width1, self.width2), False)
        return sample * self.gain