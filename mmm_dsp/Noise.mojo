from random import random_float64
from mmm_utils.functions import *

struct WhiteNoise[N: Int = 1](Copyable, Movable):
    """Generate white noise samples."""
    fn __init__(out self):
        pass  # No initialization needed for white noise

    fn next(self, gain: SIMD[DType.float64, N] = SIMD[DType.float64, N](1.0)) -> SIMD[DType.float64, N]:
        """Generate the next white noise sample.
        
        Returns:
            A random value between -gain and gain.
        """
        # Generate random value between -1 and 1, then scale by gain
        return random_lin_float64[N](-1.0, 1.0) * gain

struct PinkNoise[N: Int = 1](Copyable, Movable):
    """Generate pink noise samples (SIMD version)."""
    var b0: SIMD[DType.float64, N]
    var b1: SIMD[DType.float64, N]
    var b2: SIMD[DType.float64, N]
    var b3: SIMD[DType.float64, N]
    var b4: SIMD[DType.float64, N]
    var b5: SIMD[DType.float64, N]
    var b6: SIMD[DType.float64, N]

    fn __init__(out self):
        self.b0 = SIMD[DType.float64, N](0.0)
        self.b1 = SIMD[DType.float64, N](0.0)
        self.b2 = SIMD[DType.float64, N](0.0)
        self.b3 = SIMD[DType.float64, N](0.0)
        self.b4 = SIMD[DType.float64, N](0.0)
        self.b5 = SIMD[DType.float64, N](0.0)
        self.b6 = SIMD[DType.float64, N](0.0)

    fn next(mut self, gain: SIMD[DType.float64, N] = SIMD[DType.float64, N](1.0)) -> SIMD[DType.float64, N]:
        """Generate the next pink noise sample (SIMD) using the Voss-McCartney algorithm (https://www.firstpr.com.au/dsp/pink-noise/#Voss-McCartney).

        Args:
            gain: Amplitude scaling factor.

        Returns:
            A SIMD pink noise sample scaled by gain.
        """
        # Generate white noise SIMD
        var white = random_lin_float64[N](-1.0, 1.0)

        # Filter white noise to get pink noise (Voss-McCartney algorithm)
        self.b0 = self.b0 * 0.99886 + white * 0.0555179
        self.b1 = self.b1 * 0.99332 + white * 0.0750759
        self.b2 = self.b2 * 0.96900 + white * 0.1538520
        self.b3 = self.b3 * 0.86650 + white * 0.3104856
        self.b4 = self.b4 * 0.55000 + white * 0.5329522
        self.b5 = self.b5 * -0.7616 - white * 0.0168980

        # Sum the filtered noise sources
        var pink = self.b0 + self.b1 + self.b2 + self.b3 + self.b4 + self.b5 + self.b6 + white * 0.5362

        # Scale and return the result
        return pink * (gain * 0.125)

struct BrownNoise[N: Int = 1](Copyable, Movable):
    """Generate brown noise samples (SIMD version)."""

    var last_output: SIMD[DType.float64, N]

    fn __init__(out self):
        self.last_output = SIMD[DType.float64, N](0.0)

    fn next(mut self, gain: SIMD[DType.float64, N] = SIMD[DType.float64, N](1.0)) -> SIMD[DType.float64, N]:
        """Generate the next brown noise sample (SIMD).

        Args:
            gain: Amplitude scaling factor.

        Returns:
            A SIMD brown noise sample scaled by gain.
        """
        # Generate white noise SIMD
        var white = random_lin_float64[N](-1.0, 1.0)

        # Integrate white noise to get brown noise
        self.last_output += (white - self.last_output) * SIMD[DType.float64, N](0.02)
        return self.last_output * gain