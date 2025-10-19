from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messengers import Messenger

struct TestDelay(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Impulse[2]
    var delay: Delay[2]
    var trig: SIMD[DType.bool, 2]
    var freq: Float64
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Impulse[2](self.world_ptr)
        self.delay = Delay[2](self.world_ptr, 1.0)
        self.trig = SIMD[DType.bool, 2](True, True)
        self.freq = 0.5
        self.messenger = Messenger(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()
        sample = self.synth.next(self.freq, self.trig)  # Get the next sample from the synth
        delay = self.delay.next(sample, 0.5)
        return (delay+sample) * 0.2  # Get the next sample from the synth

    fn get_msgs(mut self: Self):
        if self.world_ptr[0].top_of_block:
            msg = self.messenger.get_list("trig")
            if self.messenger.triggered("trig"):
                for i in range(len(msg)):
                    print("Trig msg:", msg[i])
                    self.trig[i] = (msg[i] > 0)
            else:
                self.trig = SIMD[DType.bool, 2](False, False)
            self.freq = self.messenger.get_val("freq", 0.5)
