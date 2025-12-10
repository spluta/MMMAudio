"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
from mmm_dsp.Delays import *
from mmm_utils.functions import *


from mmm_dsp.Osc import *


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestCombAllpass(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Impulse[1]
    var messenger: Messenger
    var which: Float64
    var comb: Comb[1, DelayInterpOptions.lagrange]
    var allpass: Allpass_Comb[1, DelayInterpOptions.lagrange]
    var comb2: Comb[1, DelayInterpOptions.lagrange]
    var allpass2: Allpass_Comb[1, DelayInterpOptions.lagrange]
    var delay_time: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Impulse[1](self.world_ptr)
        self.messenger = Messenger(world_ptr)
        self.which = 0
        self.comb = Comb[1, DelayInterpOptions.lagrange](self.world_ptr, max_delay=2.0)
        self.allpass = Allpass_Comb[1, DelayInterpOptions.lagrange](self.world_ptr, max_delay=2.0)
        self.comb2 = Comb[1, DelayInterpOptions.lagrange](self.world_ptr, max_delay=2.0)
        self.allpass2 = Allpass_Comb[1, DelayInterpOptions.lagrange](self.world_ptr, max_delay=2.0)
        self.delay_time = 0.1

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.which, "which_fx")
        self.messenger.update(self.delay_time, "delay_time")

        sample = self.synth.next(0.4)  # Get the next sample from the synth

        comb0 = self.comb.next(sample, self.delay_time, 0.9)
        allpass0 = self.allpass.next(comb0, self.delay_time, 0.9)
        comb1 = self.comb2.next_decaytime(allpass0, self.delay_time, 1)
        allpass1 = self.allpass2.next_decaytime(comb1, self.delay_time, 1)

        sample = select(self.which, [comb0, allpass0, comb1, allpass1])

        return sample * 0.2  # Get the next sample from the synth