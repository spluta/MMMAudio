from random import random_float64
from mmm_utils.functions import *

struct WhiteNoise[num_chans: Int = 1](Copyable, Movable):
    """Generate white noise samples.
    
    Params:
        num_chans: Number of SIMD channels.

    Public Methods:
        next(gain): Generate the next white noise sample.
    
    """
    fn __init__(out self):
        pass  # No initialization needed for white noise

    fn next(self, gain: SIMD[DType.float64, num_chans] = SIMD[DType.float64, num_chans](1.0)) -> SIMD[DType.float64, num_chans]:
        """Generate the next white noise sample.
        
        Returns:
            A random value between -gain and gain.
        """
        # Generate random value between -1 and 1, then scale by gain
        return random_lin_float64[num_chans](-1.0, 1.0) * gain

struct PinkNoise[num_chans: Int = 1](Copyable, Movable):
    """Generate pink noise samples (SIMD version).

    Params:
        num_chans: Number of SIMD channels.

    Public Methods:
        next(gain): Generate the next white noise sample.
    """

    var b0: SIMD[DType.float64, num_chans]
    var b1: SIMD[DType.float64, num_chans]
    var b2: SIMD[DType.float64, num_chans]
    var b3: SIMD[DType.float64, num_chans]
    var b4: SIMD[DType.float64, num_chans]
    var b5: SIMD[DType.float64, num_chans]
    var b6: SIMD[DType.float64, num_chans]

    fn __init__(out self):
        self.b0 = SIMD[DType.float64, num_chans](0.0)
        self.b1 = SIMD[DType.float64, num_chans](0.0)
        self.b2 = SIMD[DType.float64, num_chans](0.0)
        self.b3 = SIMD[DType.float64, num_chans](0.0)
        self.b4 = SIMD[DType.float64, num_chans](0.0)
        self.b5 = SIMD[DType.float64, num_chans](0.0)
        self.b6 = SIMD[DType.float64, num_chans](0.0)

    fn next(mut self, gain: SIMD[DType.float64, num_chans] = SIMD[DType.float64, num_chans](1.0)) -> SIMD[DType.float64, num_chans]:
        """Generate the next pink noise sample (SIMD) using the Voss-McCartney algorithm (https://www.firstpr.com.au/dsp/pink-noise/#Voss-McCartney).

        Args:
            gain: Amplitude scaling factor.

        Returns:
            A SIMD pink noise sample scaled by gain.
        """
        # Generate white noise SIMD
        var white = random_lin_float64[num_chans](-1.0, 1.0)

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

struct BrownNoise[num_chans: Int = 1](Copyable, Movable):
    """Generate brown noise samples (SIMD version).

    Params:
        num_chans: Number of SIMD channels.

    Public Methods:
        next(gain): Generate the next brown noise sample.
    """

    var last_output: SIMD[DType.float64, num_chans]

    fn __init__(out self):
        self.last_output = SIMD[DType.float64, num_chans](0.0)

    fn next(mut self, gain: SIMD[DType.float64, num_chans] = SIMD[DType.float64, num_chans](1.0)) -> SIMD[DType.float64, num_chans]:
        """Generate the next brown noise sample (SIMD).

        Args:
            gain: Amplitude scaling factor.

        Returns:
            A SIMD brown noise sample scaled by gain.
        """
        # Generate white noise SIMD
        var white = random_lin_float64[num_chans](-1.0, 1.0)

        # Integrate white noise to get brown noise
        self.last_output += (white - self.last_output) * SIMD[DType.float64, num_chans](0.02)
        return self.last_output * gain

struct TExpRand[num_simd: Int = 1](Copyable, Movable):
    """Generate exponentially distributed random samples upon receiving a trigger (SIMD version).

    Params:

        num_simd: Number of SIMD channels.

    Public Methods:

        next(min, max, trig): Generate the next exponentially distributed random sample.
    """

    var stored_output: SIMD[DType.float64, num_simd]
    var last_trig: SIMD[DType.bool, num_simd]

    fn __init__(out self):
        self.stored_output = SIMD[DType.float64, num_simd](0.0)
        self.last_trig = SIMD[DType.bool, num_simd](fill=False)

    fn next(mut self, min: SIMD[DType.float64, num_simd], max: SIMD[DType.float64, num_simd], trig: SIMD[DType.bool, num_simd]) -> SIMD[DType.float64, num_simd]:
        """Generate the next exponentially distributed random sample when triggered."""
        
        rising_edge: SIMD[DType.bool, self.num_simd] = trig & ~self.last_trig
        @parameter
        for i in range(num_simd):
            if rising_edge[i]:
                self.stored_output[i] = random_exp_float64(min[i], max[i])
        self.last_trig = trig
        return self.stored_output

struct TRand[num_simd: Int = 1](Copyable, Movable):
     """Generate linearly distributed random samples upon receiving a trigger (SIMD version).

    Params:

        num_simd: Number of SIMD channels.

    Public Methods:

        next(min, max, trig): Generate the next linearly distributed random sample.
    """

    var stored_output: SIMD[DType.float64, num_simd]
    var last_trig: SIMD[DType.bool, num_simd]

    fn __init__(out self):
        self.stored_output = SIMD[DType.float64, num_simd](0.0)
        self.last_trig = SIMD[DType.bool, num_simd](fill=False)

    fn next(mut self, min: SIMD[DType.float64, num_simd], max: SIMD[DType.float64, num_simd], trig: SIMD[DType.bool, num_simd]) -> SIMD[DType.float64, num_simd]:
        """Generate the next linearly distributed random sample when triggered."""

        rising_edge: SIMD[DType.bool, self.num_simd] = trig & ~self.last_trig
        @parameter
        for i in range(num_simd):
            if rising_edge[i]:
                self.stored_output[i] = random_float64(min[i], max[i])
        self.last_trig = trig
        return self.stored_output
