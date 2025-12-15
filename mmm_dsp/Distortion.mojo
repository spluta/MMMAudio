from mmm_src.MMMWorld import MMMWorld
from math import tanh, floor
from mmm_utils.RisingBoolDetector import RisingBoolDetector

fn vtanh[N: Int](in_samp: SIMD[DType.float64, N], gain: SIMD[DType.float64, N], offset: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    var out_samp = tanh(in_samp * gain + offset)
    return out_samp

fn bitcrusher[N: Int](in_samp: SIMD[DType.float64, N], bits: Int64) -> SIMD[DType.float64, N]:
    var step = 1.0 / SIMD[DType.float64, N](1 << bits)
    var out_samp = floor(in_samp / step + 0.5) * step

    return out_samp

struct Latch[N: Int = 1](Copyable, Movable, Representable):
    var world: UnsafePointer[MMMWorld]
    var samp: SIMD[DType.float64, N]
    var last_trig: SIMD[DType.bool, N]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.samp = SIMD[DType.float64, N](0)
        self.last_trig = SIMD[DType.bool, N](False)

    fn __repr__(self) -> String:
        return String("Latch")

    fn next(mut self, in_samp: SIMD[DType.float64, self.N], trig: SIMD[DType.bool, self.N]) -> SIMD[DType.float64, self.N]:
        rising_edge: SIMD[DType.bool, self.N] = trig & ~self.last_trig
        self.samp = rising_edge.select(in_samp, self.samp)
        self.last_trig = trig
        return self.samp
        # @parameter
        # for i in range(self.N):
        #     if trig[i] and not self.last_trig[i]:
        #         self.samp[i] = in_samp[i]  # Latch the sample when the trigger goes high
        #     self.last_trig[i] = trig[i]
        # return self.samp