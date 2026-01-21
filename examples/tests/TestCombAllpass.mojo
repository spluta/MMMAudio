
from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestCombAllpass(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var synth: Impulse[1]
    var messenger: Messenger
    var which: Float64
    var comb: Comb[1, Interp.lagrange4]
    var allpass: Allpass_Comb[1, Interp.lagrange4]
    var comb2: Comb[1, Interp.lagrange4]
    var allpass2: Allpass_Comb[1, Interp.lagrange4]
    var LP_Comb: LP_Comb[1, Interp.lagrange4]
    var delay_time: Float64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.synth = Impulse[1](self.world)
        self.messenger = Messenger(world)
        self.which = 0
        self.comb = Comb[1, Interp.lagrange4](self.world, max_delay=2.0)
        self.allpass = Allpass_Comb[1, Interp.lagrange4](self.world, max_delay=2.0)
        self.comb2 = Comb[1, Interp.lagrange4](self.world, max_delay=2.0)
        self.allpass2 = Allpass_Comb[1, Interp.lagrange4](self.world, max_delay=2.0)
        self.LP_Comb = LP_Comb[1, Interp.lagrange4](self.world, max_delay=2.0)
        self.delay_time = 0.1

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.which, "which_fx")
        self.messenger.update(self.delay_time, "delay_time")

        sample = self.synth.next(0.4)  # Get the next sample from the synth

        comb0 = self.comb.next(sample, self.delay_time, 0.9)
        allpass0 = self.allpass.next(sample, self.delay_time, 0.9)
        comb1 = self.comb2.next_decaytime(sample, self.delay_time, 1)
        allpass1 = self.allpass2.next_decaytime(sample, self.delay_time, 1)
        lp_comb = self.LP_Comb.next(sample, self.delay_time, 0.9, 10000.0)

        filt = select(self.which, [comb0, allpass0, comb1, allpass1, lp_comb])

        return SIMD[DType.float64, 2](sample, filt)