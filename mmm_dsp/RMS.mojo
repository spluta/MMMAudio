from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.BufferedProcess import BufferedProcessable
from math import sqrt
from mmm_utils.functions import ampdb

# This is probably just a test for BufferedProcess. One can 
# clearly compute the RMS without so much ado.

struct RMS(BufferedProcessable):
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

    fn get_messages(mut self) -> None:
        pass

    fn next_window(mut self, mut input: List[Float64]) -> None:
        var sum_sq: Float64 = 0.0
        for v in input:
            sum_sq += v * v
        var rms: Float64 = sqrt(sum_sq / Float64(len(input)))
        rms = ampdb(rms)
        for ref v in input:
            v = rms