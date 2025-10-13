from mmm_src.MMMWorld import MMMWorld
from math import tanh, floor

fn vtanh[N: Int](in_samp: SIMD[DType.float64, N], gain: SIMD[DType.float64, N], offset: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    var out_samp = tanh(in_samp * gain + offset)
    return out_samp

fn bitcrusher[N: Int](in_samp: SIMD[DType.float64, N], bits: Int64) -> SIMD[DType.float64, N]:
    var step = 1.0 / SIMD[DType.float64, N](1 << bits)
    var out_samp = floor(in_samp / step + 0.5) * step

    return out_samp

struct Latch[N: Int = 1](Copyable, Movable, Representable):
    var world_ptr: UnsafePointer[MMMWorld]
    var samp: SIMD[DType.float64, N]
    var last_trig: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.samp = SIMD[DType.float64, N](0)
        self.last_trig = SIMD[DType.float64, N](0)

    fn __repr__(self) -> String:
        return String("Latch")

    fn next(mut self, in_samp: SIMD[DType.float64, self.N], trig: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        @parameter
        for i in range(self.N):
            if trig[i] > 0 and self.last_trig[i] <= 0:
                self.samp[i] = in_samp[i]  # Latch the sample when the trigger goes high
        self.last_trig = trig
        return self.samp