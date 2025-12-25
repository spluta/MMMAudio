from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messenger import Messenger

struct TestDelay(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var synth: Phasor
    var delay: Delay
    var freq: Float64
    var messenger: Messenger

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.synth = Phasor(self.world)
        self.delay = Delay(self.world, 1.0)
        self.freq = 0.5
        self.messenger = Messenger(world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq,"freq")
        trig = self.messenger.notify_trig("trig")
        sample = self.synth.next_impulse(self.freq, SIMD[DType.bool, 1](fill=trig))  # Get the next sample from the synth
        delay = self.delay.next(sample, 0.5)
        return SIMD[DType.float64, 2](sample, delay) * 0.2  # Get the next sample from the synth
