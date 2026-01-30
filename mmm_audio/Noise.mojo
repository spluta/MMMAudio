from random import random_float64
from .functions import *

struct WhiteNoise[num_chans: Int = 1](Copyable, Movable):
    """Generate white noise samples.
    
    Parameters:
        num_chans: Number of SIMD channels.
    """
    fn __init__(out self):
        """Initialize the WhiteNoise struct."""
        pass  # No initialization needed for white noise

    fn next(self, gain: SIMD[DType.float64, Self.num_chans] = SIMD[DType.float64, Self.num_chans](1.0)) -> SIMD[DType.float64, Self.num_chans]:
        """Generate the next white noise sample.

        Args:
            gain: Amplitude scaling factor.
        
        Returns:
            A random value between -gain and gain.
        """
        # Generate random value between -1 and 1, then scale by gain
        return random_uni_float64[Self.num_chans](-1.0, 1.0) * gain

struct PinkNoise[num_chans: Int = 1](Copyable, Movable):
    """Generate pink noise samples.

    Uses the [Voss-McCartney algorithm](https://www.firstpr.com.au/dsp/pink-noise/#Voss-McCartney).

    Parameters:
        num_chans: Number of SIMD channels.
    """

    var b0: SIMD[DType.float64, Self.num_chans]
    var b1: SIMD[DType.float64, Self.num_chans]
    var b2: SIMD[DType.float64, Self.num_chans]
    var b3: SIMD[DType.float64, Self.num_chans]
    var b4: SIMD[DType.float64, Self.num_chans]
    var b5: SIMD[DType.float64, Self.num_chans]
    var b6: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self):
        """Initialize the PinkNoise struct."""
        self.b0 = SIMD[DType.float64, Self.num_chans](0.0)
        self.b1 = SIMD[DType.float64, Self.num_chans](0.0)
        self.b2 = SIMD[DType.float64, Self.num_chans](0.0)
        self.b3 = SIMD[DType.float64, Self.num_chans](0.0)
        self.b4 = SIMD[DType.float64, Self.num_chans](0.0)
        self.b5 = SIMD[DType.float64, Self.num_chans](0.0)
        self.b6 = SIMD[DType.float64, Self.num_chans](0.0)

    fn next(mut self, gain: SIMD[DType.float64, Self.num_chans] = SIMD[DType.float64, Self.num_chans](1.0)) -> SIMD[DType.float64, Self.num_chans]:
        """Generate the next pink noise sample.

        Args:
            gain: Amplitude scaling factor.

        Returns:
            The next pink noise sample scaled by gain.
        """
        # Generate white noise SIMD
        var white = random_uni_float64[Self.num_chans](-1.0, 1.0)

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
    """Generate brown noise samples.

    Parameters:
        num_chans: Number of SIMD channels.
    """

    var last_output: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self):
        """Initialize the BrownNoise struct."""
        self.last_output = SIMD[DType.float64, Self.num_chans](0.0)

    fn next(mut self, gain: SIMD[DType.float64, Self.num_chans] = SIMD[DType.float64, Self.num_chans](1.0)) -> SIMD[DType.float64, Self.num_chans]:
        """Generate the next brown noise sample.

        Args:
            gain: Amplitude scaling factor.

        Returns:
            The next brown noise sample scaled by gain.
        """
        # Generate white noise SIMD
        var white = random_uni_float64[Self.num_chans](-1.0, 1.0)

        # Integrate white noise to get brown noise
        self.last_output += (white - self.last_output) * 0.02
        return self.last_output * gain

struct TExpRand[num_chans: Int = 1](Copyable, Movable):
    """Generate exponentially distributed random value upon receiving a trigger.

    Parameters:
        num_chans: Number of SIMD channels.
    """

    var stored_output: SIMD[DType.float64, Self.num_chans]
    var last_trig: SIMD[DType.bool, Self.num_chans]
    var is_initialized: Bool

    fn __init__(out self):
        """Initialize the TExpRand struct."""
        self.stored_output = SIMD[DType.float64, Self.num_chans](0.0)
        self.last_trig = SIMD[DType.bool, Self.num_chans](fill=False)
        self.is_initialized = False

    fn next(mut self, min: SIMD[DType.float64, Self.num_chans], max: SIMD[DType.float64, Self.num_chans], trig: SIMD[DType.bool, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Output the exponentially distributed random value.

        The value is repeated until a new trigger is received, at which point a new value is generated.
        And that new value is repeated until the next trigger, and so on.
        
        Args:
            min: Minimum value for the random value.
            max: Maximum value for the random value.
            trig: Trigger to generate a new value.

        Returns:
            The exponentially distributed random value.
        """
        
        if not self.is_initialized: 
            @parameter
            for i in range(Self.num_chans):
                self.stored_output[i] = random_exp_float64(min[i], max[i])
            self.is_initialized = True
            return self.stored_output
        
        rising_edge: SIMD[DType.bool, Self.num_chans] = trig & ~self.last_trig
        @parameter
        for i in range(Self.num_chans):
            if rising_edge[i]:
                self.stored_output[i] = random_exp_float64(min[i], max[i])
        self.last_trig = trig
        return self.stored_output

struct TRand[num_chans: Int = 1](Copyable, Movable):
     """Generate uniformly distributed random value upon receiving a trigger.

    Parameters:
        num_chans: Number of SIMD channels.
    """

    var stored_output: SIMD[DType.float64, Self.num_chans]
    var last_trig: SIMD[DType.bool, Self.num_chans]
    var is_initialized: Bool

    fn __init__(out self):
        """Initialize the TRand struct."""
        self.stored_output = SIMD[DType.float64, Self.num_chans](0.0)
        self.last_trig = SIMD[DType.bool, Self.num_chans](fill=False)
        self.is_initialized = False

    fn next(mut self, min: SIMD[DType.float64, Self.num_chans], max: SIMD[DType.float64, Self.num_chans], trig: SIMD[DType.bool, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Output uniformly distributed random value.

        The value is repeated until a new trigger is received, at which point a new value is generated.
        And that new value is repeated until the next trigger, and so on.

        Args:
            min: Minimum value for the random value.
            max: Maximum value for the random value.
            trig: Trigger to generate a new value.

        Returns:
            The uniformly distributed random value.
        """

        if not self.is_initialized: 
            @parameter
            for i in range(Self.num_chans):
                self.stored_output[i] = random_float64(min[i], max[i])
            self.is_initialized = True
            return self.stored_output

        rising_edge: SIMD[DType.bool, Self.num_chans] = trig & ~self.last_trig
        @parameter
        for i in range(Self.num_chans):
            if rising_edge[i]:
                self.stored_output[i] = random_float64(min[i], max[i])
        self.last_trig = trig
        return self.stored_output
