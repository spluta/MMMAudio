from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messenger import Messenger

struct TestDelay(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var synth: Impulse[2]
    var delay: Delay[2]
    var freq: Float64
    var messenger: Messenger

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.synth = Impulse[2](self.w)
        self.delay = Delay[2](self.w, 1.0)
        self.freq = 0.5
        self.messenger = Messenger(w)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.freq,"freq")
        trig = self.messenger.notify_trig("trig")
        sample = self.synth.next(self.freq, trig)  # Get the next sample from the synth
        delay = self.delay.next(sample, 0.5)
        return (delay+sample) * 0.2  # Get the next sample from the synth
