
from mmm_audio import *

struct TestDelay(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var synth: Phasor
    var delay: Delay
    var freq: Float64
    var messenger: Messenger

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.synth = Phasor(self.world)
        self.delay = Delay(self.world, 1.0)
        self.freq = 0.5
        self.messenger = Messenger(world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq,"freq")
        trig = self.messenger.notify_trig("trig")
        sample = self.synth.next_impulse(self.freq, 0.0, SIMD[DType.bool, 1](fill=trig))  # Get the next sample from the synth
        delay = self.delay.next(sample, 0.5)
        return SIMD[DType.float64, 2](sample, delay) * 0.2  # Get the next sample from the synth
