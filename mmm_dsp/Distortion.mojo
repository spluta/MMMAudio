from mmm_src.MMMWorld import MMMWorld
from math import tanh, floor
from mmm_utils.RisingBoolDetector import RisingBoolDetector
from mmm_utils.functions import clip

fn vtanh[num_chans: Int](in_samp: SIMD[DType.float64, num_chans], gain: SIMD[DType.float64, num_chans], offset: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    var out_samp = tanh(in_samp * gain + offset)
    return out_samp

fn bitcrusher[num_chans: Int](in_samp: SIMD[DType.float64, num_chans], bits: Int64) -> SIMD[DType.float64, num_chans]:
    var step = 1.0 / SIMD[DType.float64, num_chans](1 << bits)
    var out_samp = floor(in_samp / step + 0.5) * step

    return out_samp

from math import sin, copysign

fn buchla_cell[num_chans: Int](sig: SIMD[DType.float64, num_chans], sign: SIMD[DType.float64, num_chans], thresh: SIMD[DType.float64, num_chans], 
               sig_mul1: SIMD[DType.float64, num_chans], sign_mul: SIMD[DType.float64, num_chans], sig_mul2: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Implements the Buchla cell function"""
    var mask: SIMD[DType.bool, num_chans] = abs(sig).gt(thresh)

    return mask.select((sig * sig_mul1 - (sign * sign_mul)) * sig_mul2, 0.0)

fn sign[num_chans:Int](x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Returns the sign of x: -1, 0, or 1"""
    pmask = x.gt(0.0)
    nmask = x.lt(0.0)

    return pmask.select(SIMD[DType.float64, num_chans](1.0), nmask.select(SIMD[DType.float64, num_chans](-1.0), SIMD[DType.float64, num_chans](0.0)))

fn buchla_wavefolder[num_chans: Int](input: SIMD[DType.float64, num_chans], var amp: Float64) -> SIMD[DType.float64, num_chans]:
    """
    Buchla waveshaper implementation
    
    Args:
        phase: Phase in radians (0 to 2π for one cycle)
        amp: Amplitude/gain control (0.001 to 20 in original)
    
    Returns:
        Waveshaped output signal
    """
    # Generate sine wave at given phase
    amp = clip(amp, 1.0, 40.0)
    var sig = input * amp
    var sig_sign = sign(sig)

    # Apply Buchla cells
    var v1 = buchla_cell(sig, sig_sign, 0.6, 0.8333, 0.5, 12.0)
    var v2 = buchla_cell(sig, sig_sign, 2.994, 0.3768, 1.1281, 27.777)
    var v3 = buchla_cell(sig, sig_sign, 5.46, 0.2829, 1.5446, 21.428)
    var v4 = buchla_cell(sig, sig_sign, 1.8, 0.5743, 1.0338, 17.647)
    var v5 = buchla_cell(sig, sig_sign, 4.08, 0.2673, 1.0907, 36.363)
    var v6 = sig * 5.0
    
    out = (v1 + v2 + v3) * (-1) + (v4 + v5 + v6)

    # Scale output
    return tanh(out / amp)

struct Latch[num_chans: Int = 1](Copyable, Movable, Representable):
    var world: UnsafePointer[MMMWorld]
    var samp: SIMD[DType.float64, num_chans]
    var last_trig: SIMD[DType.bool, num_chans]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.samp = SIMD[DType.float64, num_chans](0)
        self.last_trig = SIMD[DType.bool, num_chans](False)

    fn __repr__(self) -> String:
        return String("Latch")

    fn next(mut self, in_samp: SIMD[DType.float64, self.num_chans], trig: SIMD[DType.bool, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        rising_edge: SIMD[DType.bool, self.num_chans] = trig & ~self.last_trig
        self.samp = rising_edge.select(in_samp, self.samp)
        self.last_trig = trig
        return self.samp

