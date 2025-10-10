from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_utils.Messengers import Messenger


# this is the simplest possible
struct In2Out(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.messenger = Messenger(world_ptr)

    fn __repr__(self) -> String:
        return String("In2Out")

    fn next(mut self) -> SIMD[DType.float64, 16]:
        if self.world_ptr[0].top_of_block:
            if self.messenger.triggered("print_inputs"):
                for i in range(self.world_ptr[0].num_in_chans):
                    print("input[", i, "] =", self.world_ptr[0].sound_in[i])

        # the SIMD vector has to be a power of 2
        output = SIMD[DType.float64, 16](0.0)

        # whichever is smaller, the output or the sound_in - that number of values are copied to the output
        smaller  = min(len(output), len(self.world_ptr[0].sound_in))
        for i in range(smaller):
            output[i] = self.world_ptr[0].sound_in[i]

        return output  # Return the combined output samples
