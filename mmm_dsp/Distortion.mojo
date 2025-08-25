from mmm_src.MMMWorld import MMMWorld
from math import tanh, floor

fn vtanh(in_samp: Float64, gain: Float64, offset: Float64) -> Float64:
    var out_samp = tanh(in_samp * gain + offset)
    return out_samp

fn bitcrusher(in_samp: Float64, bits: Int64) -> Float64:
    var step = 1.0 / Float64(1 << bits)
    var out_samp = floor(in_samp / step + 0.5) * step

    return out_samp

struct Latch(Copyable, Movable, Representable):
    var world_ptr: UnsafePointer[MMMWorld]
    var samp: Float64
    var last_trig: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.samp = 0
        self.last_trig = 0

    fn __repr__(self) -> String:
        return String("Latch")

    fn next(mut self, in_samp: Float64, trig: Float64) -> Float64:
        if trig > 0 and self.last_trig <= 0:
            self.samp = in_samp  # Latch the sample when the trigger goes high
        return self.samp