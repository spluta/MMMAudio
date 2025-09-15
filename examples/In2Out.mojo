from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *


# this is the simplest possible
struct In2Out(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

    fn __repr__(self) -> String:
        return String("In2Out")

    fn next(mut self) -> SIMD[DType.float64, 16]:
        self.get_msgs()

        # the SIMD vector has to be a power of 2
        output = SIMD[DType.float64, 16](0.0)

        # whichever is smaller, the output or the sound_in - that number of values are copied to the output
        smaller  = min(len(output), len(self.world_ptr[0].sound_in))
        for i in range(smaller):
            output[i] = self.world_ptr[0].sound_in[i]

        return output  # Return the combined output samples

    fn get_msgs(mut self: Self):
        # a "print_inputs" message prints the current values held in the sound_in list in the world_ptr
        msg = self.world_ptr[0].get_msg("print_inputs")
        if msg:
            for i in range(self.world_ptr[0].num_in_chans):
                print("input[", i, "] =", self.world_ptr[0].sound_in[i])