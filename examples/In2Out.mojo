from mmm_src.MMMWorld import *
from mmm_utils.functions import *

from mmm_utils.Messenger import *


# this is the simplest possible
struct In2Out(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var messenger: Messenger

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.messenger = Messenger(w)

    fn __repr__(self) -> String:
        return String("In2Out")

    fn next(mut self) -> SIMD[DType.float64, 16]:
        if self.messenger.notify_trig("print_inputs"):
            for i in range(self.w[].num_in_chans):
                print("input[", i, "] =", self.w[].sound_in[i])

        # the SIMD vector has to be a power of 2
        output = SIMD[DType.float64, 16](0.0)

        # whichever is smaller, the output or the sound_in - that number of values are copied to the output
        smaller  = min(len(output), len(self.w[].sound_in))
        for i in range(smaller):
            output[i] = self.w[].sound_in[i]

        return output  # Return the combined output samples
