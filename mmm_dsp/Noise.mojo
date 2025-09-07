from random import random_float64

struct WhiteNoise(Copyable, Movable):
    """Generate white noise samples."""
    fn __init__(out self):
        pass  # No initialization needed for white noise

    fn next(self, gain: Float64 = 1.0) -> Float64:
        """Generate the next white noise sample.
        
        Returns:
            A random value between -gain and gain.
        """
        # Generate random value between -1 and 1, then scale by gain
        return random_float64(-1.0, 1.0) * gain

struct PinkNoise(Copyable, Movable):
    """Generate pink noise samples."""
    
    var b0: Float64
    var b1: Float64
    var b2: Float64
    var b3: Float64
    var b4: Float64
    var b5: Float64
    var b6: Float64

    fn __init__(out self):
        self.b0 = 0.0
        self.b1 = 0.0
        self.b2 = 0.0
        self.b3 = 0.0
        self.b4 = 0.0
        self.b5 = 0.0
        self.b6 = 0.0

    fn next(mut self, gain: Float64 = 1.0) -> Float64:
        """Generate the next pink noise sample.
        
        Args:
            gain: Amplitude scaling factor.
            
        Returns:
            A pink noise sample scaled by gain.
        """
        # Generate white noise
        var white = 2.0 * random_float64() - 1.0
        
        # Filter white noise to get pink noise (Voss-McCartney algorithm)
        self.b0 = 0.99886 * self.b0 + white * 0.0555179
        self.b1 = 0.99332 * self.b1 + white * 0.0750759
        self.b2 = 0.96900 * self.b2 + white * 0.1538520
        self.b3 = 0.86650 * self.b3 + white * 0.3104856
        self.b4 = 0.55000 * self.b4 + white * 0.5329522
        self.b5 = -0.7616 * self.b5 - white * 0.0168980
        
        # Sum the filtered noise sources
        var pink = self.b0 + self.b1 + self.b2 + self.b3 + self.b4 + self.b5 + self.b6 + white * 0.5362
        
        # Scale and return the result
        return pink * (gain * 0.125)  # Scale appropriately

struct BrownNoise(Copyable, Movable):
    """Generate brown noise samples."""

    var last_output: Float64

    fn __init__(out self):
        self.last_output = 0.0

    fn next(mut self, gain: Float64 = 1.0) -> Float64:
        """Generate the next brown noise sample.

        Args:
            gain: Amplitude scaling factor.

        Returns:
            A brown noise sample scaled by gain.
        """
        # Generate white noise
        var white = 2.0 * random_float64() - 1.0

        # Integrate white noise to get brown noise
        self.last_output += (white - self.last_output) * 0.02
        return self.last_output * gain