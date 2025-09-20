"""
Documentation Example for Mojo Files

This module demonstrates how to write comprehensive documentation for Mojo
code that will be processed by the custom mojo_doc_adapter. Use triple-quoted
docstrings with structured sections.

This file serves as a template showing best practices for:
- Module-level documentation
- Struct documentation  
- Function documentation with generics
- Parameter and return value documentation
- Examples and usage patterns
"""

from math import sin, cos, pi, sqrt
from random import random_float64


struct AudioBuffer:
    """A generic audio buffer for storing and manipulating audio samples.
    
    This struct provides a high-performance audio buffer with SIMD optimization
    for common audio processing operations. It supports both reading and writing
    audio data with bounds checking and automatic memory management.
    
    The buffer uses SIMD operations where possible for optimal performance on
    modern processors.
    """
    
    var data: List[Float64]
    var size: Int
    var sample_rate: Int
    var channels: Int
    
    fn __init__(out self, size: Int, sample_rate: Int = 44100, channels: Int = 1):
        """Initialize an audio buffer with specified parameters.
        
        Args:
            size: Number of samples in the buffer.
            sample_rate: Sample rate in Hz (default: 44100).
            channels: Number of audio channels (default: 1).
        """
        self.size = size
        self.sample_rate = sample_rate
        self.channels = channels
        self.data = List[Float64]()
        
        # Initialize with zeros
        for i in range(size):
            self.data.append(0.0)
    
    fn clear(mut self):
        """Clear the buffer by setting all samples to zero.
        
        This method efficiently zeros out the entire buffer using vectorized
        operations when possible.
        
        Examples:
            buffer = AudioBuffer(1024)
            buffer.fill_with_sine(440.0)
            buffer.clear()  # All samples now zero
        """
        for i in range(self.size):
            self.data[i] = 0.0
    
    fn get_sample(self, index: Int) -> Float64:
        """Get a sample at the specified index with bounds checking.
        
        Args:
            index: Sample index (0-based).
            
        Returns:
            Sample value at the specified index, or 0.0 if out of bounds.
            
        Examples:
            buffer = AudioBuffer(1024)
            sample = buffer.get_sample(100)
        """
        if index >= 0 and index < self.size:
            return self.data[index]
        return 0.0
    
    fn set_sample(mut self, index: Int, value: Float64):
        """Set a sample at the specified index with bounds checking.
        
        Args:
            index: Sample index (0-based).
            value: Sample value to set.
            
        Examples:
            buffer = AudioBuffer(1024)
            buffer.set_sample(100, 0.5)
        """
        if index >= 0 and index < self.size:
            self.data[index] = value


fn generate_sine_wave[N: Int = 1](frequency: SIMD[DType.float64, N], 
                                  phase: SIMD[DType.float64, N], 
                                  sample_rate: Float64 = 44100.0) -> SIMD[DType.float64, N]:
    """Generate sine wave samples at specified frequency and phase.
    
    This function generates sine wave samples using SIMD operations for optimal
    performance. It supports vectorized generation of multiple sine waves
    simultaneously.
    
    Parameters:
        N: SIMD vector width (number of simultaneous sine waves).
    
    Args:
        frequency: Frequency in Hz for each sine wave.
        phase: Current phase in radians for each sine wave.
        sample_rate: Sample rate in Hz (default: 44100.0).
        
    Returns:
        SIMD vector containing sine wave sample values.
        
    Examples:
        # Generate single sine wave sample
        sample = generate_sine_wave(440.0, 0.0)
        
        # Generate 4 different frequencies simultaneously
        freqs = SIMD[DType.float64, 4](440.0, 880.0, 1320.0, 1760.0)
        phases = SIMD[DType.float64, 4](0.0, 0.0, 0.0, 0.0)
        samples = generate_sine_wave[4](freqs, phases)
    """
    var angular_freq = 2.0 * pi * frequency / sample_rate
    return sin(phase + angular_freq)


fn linear_interpolate[N: Int = 1](x0: SIMD[DType.float64, N], 
                                  y0: SIMD[DType.float64, N],
                                  x1: SIMD[DType.float64, N], 
                                  y1: SIMD[DType.float64, N],
                                  x: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """Perform linear interpolation between two points using SIMD operations.
    
    This function implements vectorized linear interpolation using the formula:
    y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    
    All operations are performed using SIMD vectors for maximum performance
    when processing multiple interpolations simultaneously.
    
    Parameters:
        N: SIMD vector width (default: 1).
    
    Args:
        x0: X coordinates of first points.
        y0: Y coordinates of first points.
        x1: X coordinates of second points.
        y1: Y coordinates of second points.
        x: X coordinates where to interpolate.
        
    Returns:
        Interpolated Y values at positions x.
        
    Examples:
        # Single interpolation
        result = linear_interpolate(0.0, 1.0, 1.0, 2.0, 0.5)  # Returns 1.5
        
        # Vectorized interpolation of 4 points
        x0_vec = SIMD[DType.float64, 4](0.0, 1.0, 2.0, 3.0)
        y0_vec = SIMD[DType.float64, 4](1.0, 2.0, 3.0, 4.0)
        x1_vec = SIMD[DType.float64, 4](1.0, 2.0, 3.0, 4.0)
        y1_vec = SIMD[DType.float64, 4](2.0, 3.0, 4.0, 5.0)
        x_vec = SIMD[DType.float64, 4](0.5, 1.5, 2.5, 3.5)
        
        results = linear_interpolate[4](x0_vec, y0_vec, x1_vec, y1_vec, x_vec)
    """
    var dx = x1 - x0
    var dy = y1 - y0
    var t = (x - x0) / dx
    return y0 + dy * t


fn apply_gain[N: Int = 1](mut signal: SIMD[DType.float64, N], 
                          gain: SIMD[DType.float64, N]):
    """Apply gain to audio signal in-place using SIMD operations.
    
    This function multiplies the input signal by the specified gain values.
    The operation is performed in-place to minimize memory allocations.
    
    Parameters:
        N: SIMD vector width (default: 1).
    
    Args:
        signal: Audio signal to modify (modified in-place).
        gain: Gain values to apply (linear, not dB).
        
    Examples:
        # Apply 6dB gain boost (linear gain ≈ 2.0)
        var audio = SIMD[DType.float64, 1](0.5)
        apply_gain(audio, 2.0)  # audio is now 1.0
        
        # Apply different gains to multiple channels
        var multichannel = SIMD[DType.float64, 4](0.1, 0.2, 0.3, 0.4)
        var gains = SIMD[DType.float64, 4](1.0, 2.0, 0.5, 1.5)
        apply_gain[4](multichannel, gains)
    """
    signal = signal * gain


fn generate_white_noise[N: Int = 1](amplitude: SIMD[DType.float64, N] = 1.0) -> SIMD[DType.float64, N]:
    """Generate white noise with specified amplitude.
    
    This function generates uniformly distributed white noise in the range
    [-amplitude, amplitude] using the built-in random number generator.
    
    Parameters:
        N: SIMD vector width (default: 1).
    
    Args:
        amplitude: Peak amplitude of the noise (default: 1.0).
        
    Returns:
        SIMD vector containing white noise samples.
        
    Examples:
        # Generate single noise sample
        noise = generate_white_noise(0.1)  # Quiet noise
        
        # Generate multiple noise samples with different amplitudes
        amplitudes = SIMD[DType.float64, 4](0.1, 0.2, 0.3, 0.4)
        noise_samples = generate_white_noise[4](amplitudes)
    """
    var result = SIMD[DType.float64, N](0.0)
    
    for i in range(N):
        # Generate random value in [-1, 1] range
        var random_val = (random_float64() - 0.5) * 2.0
        result[i] = random_val * amplitude[i]
    
    return result
