from mmm_src.MMMWorld import MMMWorld
from math import tanh, floor, pi, exp
from mmm_utils.RisingBoolDetector import RisingBoolDetector
from mmm_utils.functions import clip
from mmm_dsp.Utils import Li2
from mmm_dsp.Oversampling import *


fn bitcrusher[num_chans: Int](in_samp: SIMD[DType.float64, num_chans], bits: Int64) -> SIMD[DType.float64, num_chans]:
    var step = 1.0 / SIMD[DType.float64, num_chans](1 << bits)
    var out_samp = floor(in_samp / step + 0.5) * step

    return out_samp

from math import sin, copysign, log, cosh

fn buchla_cell[num_chans: Int](sig: SIMD[DType.float64, num_chans], sign: SIMD[DType.float64, num_chans], thresh: SIMD[DType.float64, num_chans], 
               sig_mul1: SIMD[DType.float64, num_chans], sign_mul: SIMD[DType.float64, num_chans], sig_mul2: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Implements the Buchla cell function"""
    var mask: SIMD[DType.bool, num_chans] = abs(sig).gt(thresh)

    return mask.select((sig * sig_mul1 - (sign * sign_mul)) * sig_mul2, 0.0)

fn sign[num_chans:Int](x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Returns the sign of x: -1, 0, or 1"""
    pmask:SIMD[DType.bool, num_chans] = x.gt(0.0)
    nmask:SIMD[DType.bool, num_chans] = x.lt(0.0)

    return pmask.select(SIMD[DType.float64, num_chans](1.0), nmask.select(SIMD[DType.float64, num_chans](-1.0), SIMD[DType.float64, num_chans](0.0)))

fn buchla_wavefolder[num_chans: Int](input: SIMD[DType.float64, num_chans], var amp: Float64) -> SIMD[DType.float64, num_chans]:
    """
    Buchla waveshaper implementation
    
    Args:
        input: Signal in - between 0 and +/-40.
        amp: Amplitude/gain control (1 to 40).
    
    Returns:
        Waveshaped output signal
    """
    # Generate sine wave at given phase
    amp = clip(amp, 1.0, 40.0)
    var sig = input * amp
    var sig_sign = sign(sig)

    # Apply Buchla cells
    var v1 = buchla_cell(sig, sig_sign, 0.6, 0.8333, 0.5, -12.0)
    var v2 = buchla_cell(sig, sig_sign, 2.994, 0.3768, 1.1281, -27.777)
    var v3 = buchla_cell(sig, sig_sign, 5.46, 0.2829, 1.5446, -21.428)
    var v4 = buchla_cell(sig, sig_sign, 1.8, 0.5743, 1.0338, 17.647)
    var v5 = buchla_cell(sig, sig_sign, 4.08, 0.2673, 1.0907, 36.363)
    var v6 = sig * 5.0
    
    out = (v1 + v2 + v3) + (v4 + v5 + v6)

    # Scale output
    return tanh(out / amp)

struct Latch[num_chans: Int = 1](Copyable, Movable, Representable):
    var samp: SIMD[DType.float64, num_chans]
    var last_trig: SIMD[DType.bool, num_chans]

    fn __init__(out self):
        self.samp = SIMD[DType.float64, num_chans](0)
        self.last_trig = SIMD[DType.bool, num_chans](False)

    fn __repr__(self) -> String:
        return String("Latch")

    fn next(mut self, in_samp: SIMD[DType.float64, self.num_chans], trig: SIMD[DType.bool, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        rising_edge: SIMD[DType.bool, self.num_chans] = trig & ~self.last_trig
        self.samp = rising_edge.select(in_samp, self.samp)
        self.last_trig = trig
        return self.samp

# Anti-Derivative Anti-Aliasing functions are based on Jatin Chowdhury's python notebook: https://ccrma.stanford.edu/~jatin/Notebooks/adaa.html

# the trait currently doesn't work, but it will once parameters are included in traits

# trait ADAAfuncs[num_chans: Int = 1](Movable, Copyable):

#     fn next_norm[num_chans: Int](mut self, input: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
#         ...

#     fn next_AD1[num_chans: Int](mut self, input: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
#         ...
    
#     fn next_AD2[num_chans: Int](mut self, input: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
#         ...

struct SoftClipAD[num_chans: Int = 1, os_index: Int = 0, degree: Int = 3](Copyable, Movable):
    """
    Anti-Derivative Anti-Aliasing hard-clipping function.
    
    This struct provides first and second order anti-aliased versions of the `hard_clip` function using the Anti-Derivative Anti-Aliasing (ADAA)
    
    Params:
    
        num_chans: The number of channels for SIMD operations.
    
    Methods:

        next1(x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
            Computes the first order anti-aliased `hard_clip` of `x`.
        next2(x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
            Computes the second order anti-aliased `hard_clip` of `x`.
    
    """
    alias times_oversampling = 2 ** os_index
    var x1: SIMD[DType.float64, num_chans]
    var oversampling: Oversampling[num_chans, Self.times_oversampling]
    var upsampler: Upsampler[num_chans, Self.times_oversampling]
    var degree_use: Int
    alias TOL = 1.0e-5

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.x1 = SIMD[DType.float64, num_chans](0.0)
        if os_index > 1:
            print("SoftClipAD: os_index greater than 1 not supported yet. It will not sound good.")
        self.oversampling = Oversampling[num_chans, Self.times_oversampling](world)
        self.upsampler = Upsampler[num_chans, 2 ** os_index](world)
        self.degree_use = degree // 2 * 2 + 1  # ensure degree is odd

    @doc_private
    @always_inline
    fn _next_norm(mut self, x: SIMD[DType.float64, num_chans], thresh: Float64 = 1.0) -> SIMD[DType.float64, num_chans]:
        """Transfer function: x - x^n/n"""
        
        x_norm = clip(x / thresh, -1.0, 1.0)
        return (x_norm - pow(x_norm, self.degree_use) / self.degree_use) * thresh

    @doc_private
    @always_inline
    fn _next_AD1(mut self, x: SIMD[DType.float64, num_chans], thresh: Float64 = 1.0) -> SIMD[DType.float64, num_chans]:
        """First antiderivative: x²/2 - x^(n+1) / (n*(n+1))"""
        x_norm = clip(x / thresh, -1.0, 1.0)
        n = self.degree_use
        result = x_norm**2 / 2 - pow(x_norm, n + 1) / (n * (n + 1))
        return result * (thresh ** 2)

    @doc_private
    @always_inline
    fn _next1(mut self, x: SIMD[DType.float64, num_chans], thresh: Float64 = 1.0) -> SIMD[DType.float64, num_chans]:
        diff = x - self.x1
        abs_x = abs(x)
        abs_x1 = abs(self.x1)
        
        mask = abs(diff).lt(self.TOL) | abs_x.gt(thresh) | abs_x1.gt(thresh) 
        
        fallback = self._next_norm(x, thresh)
        
        ad1_curr = self._next_AD1(x, thresh)
        ad1_prev = self._next_AD1(self.x1, thresh)
        # Avoid division by zero in lanes where diff is small
        safe_diff = mask.select(SIMD[DType.float64, num_chans](1.0), diff)
        normal = (ad1_curr - ad1_prev) / safe_diff
        
        out = mask.select(fallback, normal)
        
        self.x1 = x
        return out

    @always_inline
    fn next1(mut self, x: SIMD[DType.float64, num_chans], thresh: Float64 = 1.0) -> SIMD[DType.float64, num_chans]:
        """
        Computes the first-order anti-aliased `hard_clip` of `x`.

        Args:
            x: The input sample.

        Returns:
            The anti-aliased `hard_clip` of `x`.
        """
        @parameter
        if os_index == 0:
            return self._next1(x, thresh)
        else:
            @parameter
            for i in range(self.times_oversampling):
                # upsample the input
                x2 = self.upsampler.next(x, i)
                y = self._next1(x2, thresh)
                self.oversampling.add_sample(y)
            return self.oversampling.get_sample()

fn hard_clip[num_chans: Int](x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        return x if abs(x) < 1 else sign(x)

struct HardClipAD[num_chans: Int = 1, os_index: Int = 0](Copyable, Movable):
    """
    Anti-Derivative Anti-Aliasing hard-clipping function.
    
    This struct provides first and second order anti-aliased versions of the `hard_clip` function using the Anti-Derivative Anti-Aliasing (ADAA)
    
    Params:
    
        num_chans: The number of channels for SIMD operations.
    
    Methods:

        next1(x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
            Computes the first order anti-aliased `hard_clip` of `x`.
        next2(x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
            Computes the second order anti-aliased `hard_clip` of `x`.
    
    """
    var x1: SIMD[DType.float64, num_chans]
    var x2: SIMD[DType.float64, num_chans]
    var oversampling: Oversampling[num_chans, 2 ** os_index]
    var upsampler: Upsampler[num_chans, 2 ** os_index]
    alias TOL = 1.0e-5

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.x1 = SIMD[DType.float64, num_chans](0.0)
        self.x2 = SIMD[DType.float64, num_chans](0.0)
        self.oversampling = Oversampling[num_chans, 2 ** os_index](world)
        self.upsampler = Upsampler[num_chans, 2 ** os_index](world)

    @doc_private
    @always_inline
    fn _next_norm(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        mask: SIMD[DType.bool, num_chans] = abs(x).lt(1.0)
        return mask.select(x, sign(x))

    @doc_private
    @always_inline
    fn _next_AD1(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        mask: SIMD[DType.bool, num_chans] = abs(x).lt(1.0)
        return mask.select(x * x * 0.5, x * sign(x) - 0.5)

    @doc_private
    @always_inline
    fn _next_AD2(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        mask: SIMD[DType.bool, num_chans] = abs(x).lt(1.0)

        return mask.select(x * x * x / 6.0, ((x * x * 0.5) + (1.0 / 6.0)) * sign(x) - (x/2))

    @doc_private
    @always_inline
    fn _calcD(mut self, x0: SIMD[DType.float64, num_chans], x1: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:

        mask: SIMD[DType.bool, num_chans] = abs(x0 - x1).lt(self.TOL)

        return mask.select(
            self._next_AD1((x0 + x1) * 0.5),
            (self._next_AD2(x0) - self._next_AD2(x0) - self._next_AD2(x1)) / (x0 - x1)
        )

    @doc_private
    @always_inline
    fn _fallback(mut self, x0: SIMD[DType.float64, num_chans], x2: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        x_bar = (x0 + x2) * 0.5
        delta = x_bar - x0

        mask: SIMD[DType.bool, num_chans] = abs(delta).lt(self.TOL)  # Changed to abs(delta)
        return mask.select(
            self._next_norm((x_bar + x0) * 0.5),
            (2.0 / delta) * (self._next_AD1(x_bar) + (self._next_AD2(x0) - self._next_AD2(x_bar)) / delta)
        )

    @doc_private
    @always_inline
    fn _next1(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        mask: SIMD[DType.bool, num_chans] = abs(x - self. x1).lt(self.TOL)
        out = mask.select(self._next_norm((x + self.x1) * 0.5), (self._next_AD1(x) - self._next_AD1(self.x1)) / (x - self.x1))
        self.x1 = x
        return out

    @always_inline
    fn next1(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        """
        Computes the first-order anti-aliased `hard_clip` of `x`.

        Args:
            x: The input sample.

        Returns:
            The anti-aliased `hard_clip` of `x`.
        """
        @parameter
        if os_index == 0:
            return self._next1(x)
        else:
            alias times_oversampling = 2 ** os_index
            @parameter
            for i in range(times_oversampling):
                # upsample the input
                x2 = self.upsampler.next(x, i)
                y = self._next1(x2)
                self.oversampling.add_sample(y)
            return self.oversampling.get_sample()
    
struct TanhAD[num_chans: Int = 1](Copyable, Movable):
    """
    Anti-Derivative Anti-Aliasing first order tanh function.
    This struct provides anti-aliased versions of the `tanh` function using the Anti-Derivative Anti-Aliasing (ADAA) method.
    It currently implements the first-order ADAA function `next1`.

    Parameters:
        num_chans: The number of channels for SIMD operations.

    Methods:
        __init__(): Initializes the `TanhAD` struct.

        next1(x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
            Computes the first-order anti-aliased `tanh` of `x`.
            This method should be called iteratively for each sample.

    Example:
        var tanhad = TanhAD[1]()
        var output = tanhad.next1(input_sample)

    tanhad.next1(x: SIMD[DType.float64, num_chans]).
    """

    var x1: SIMD[DType.float64, num_chans]
    # var x2: SIMD[DType.float64, num_chans]
    alias TOL = 1.0e-5

    fn __init__(out self):
        self.x1 = SIMD[DType.float64, num_chans](0.0)
        # self.x2 = SIMD[DType.float64, num_chans](0.0)

    @doc_private
    fn _next_norm(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        return tanh(x)

    @doc_private
    fn _next_AD1(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        return log (cosh (x))

    fn next1(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        """
        Computes the first-order anti-aliased `tanh` of `x`.
        This method should be called iteratively for each sample.

        Args:
            x: The input sample.

        Returns:
            The anti-aliased `tanh` of `x`.
        """
        mask: SIMD[DType.bool, num_chans] = abs(x - self. x1).lt(self.TOL)

        out = mask.select(self._next_norm((x + self.x1) * 0.5), (self._next_AD1(x) - self._next_AD1(self.x1)) / (x - self.x1))
        self.x1 = x
        return out
