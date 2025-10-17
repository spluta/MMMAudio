from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messengers import Messenger

struct TestDelay(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Impulse
    var delay: Delay
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Impulse(self.world_ptr)
        self.delay = Delay(self.world_ptr, 1.0)
        self.m = Messenger(self.world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        trig = self.m.triggered("trig")
        freq = self.m.get_val("freq", 440.0)
        sample = self.synth.next(freq, trig)
        delay = self.delay.next(sample, 0.5)
        return (delay+sample) * 0.2  