"""
Documentation Example for Python Files

This module demonstrates how to write comprehensive documentation for Python
code that will be processed by mkdocs with mkdocstrings. Use Google-style
docstrings for consistency.

This file serves as a template showing best practices for:
- Module-level documentation
- Class documentation  
- Function documentation
- Type hints and parameter documentation
- Examples and usage patterns
"""

from typing import List, Optional, Union, Dict, Any
import numpy as np


class AudioProcessor:
    """A sample audio processing class demonstrating documentation patterns.
    
    This class shows how to document classes with proper type hints,
    comprehensive parameter descriptions, and usage examples.
    
    Attributes:
        sample_rate: The sample rate in Hz for audio processing.
        buffer_size: Size of internal audio buffer.
        is_active: Whether the processor is currently active.
        
    Example:
        Basic usage of the AudioProcessor:
        
        ```python
        processor = AudioProcessor(sample_rate=44100, buffer_size=512)
        processor.initialize()
        
        # Process some audio
        input_signal = np.random.randn(1024)
        output = processor.process(input_signal)
        ```
    """
    
    def __init__(self, sample_rate: int = 44100, buffer_size: int = 512) -> None:
        """Initialize the audio processor.
        
        Args:
            sample_rate: Sample rate in Hz. Must be positive.
            buffer_size: Internal buffer size. Should be power of 2 for efficiency.
            
        Raises:
            ValueError: If sample_rate <= 0 or buffer_size <= 0.
        """
        if sample_rate <= 0:
            raise ValueError("Sample rate must be positive")
        if buffer_size <= 0:
            raise ValueError("Buffer size must be positive")
            
        self.sample_rate = sample_rate
        self.buffer_size = buffer_size
        self.is_active = False
        self._internal_buffer: List[float] = []
    
    def initialize(self) -> bool:
        """Initialize the processor and allocate resources.
        
        This method sets up internal state and allocates necessary buffers.
        Call this before processing audio.
        
        Returns:
            True if initialization successful, False otherwise.
            
        Example:
            ```python
            processor = AudioProcessor()
            if processor.initialize():
                print("Ready to process audio")
            else:
                print("Initialization failed")
            ```
        """
        try:
            self._internal_buffer = [0.0] * self.buffer_size
            self.is_active = True
            return True
        except Exception:
            return False
    
    def process(self, 
                input_data: Union[List[float], np.ndarray], 
                gain: float = 1.0,
                normalize: bool = False) -> np.ndarray:
        """Process audio data with optional gain and normalization.
        
        This is the main processing method that applies gain and optional
        normalization to the input audio data.
        
        Args:
            input_data: Input audio samples as list or numpy array.
            gain: Gain factor to apply (default: 1.0 = unity gain).
            normalize: Whether to normalize output to [-1, 1] range.
            
        Returns:
            Processed audio data as numpy array.
            
        Raises:
            RuntimeError: If processor not initialized.
            ValueError: If input_data is empty or gain is negative.
            
        Example:
            Process audio with gain boost:
            
            ```python
            processor = AudioProcessor()
            processor.initialize()
            
            # Apply 6dB gain boost
            input_signal = [0.1, 0.2, -0.1, 0.3]
            output = processor.process(input_signal, gain=2.0)
            ```
            
            Process with normalization:
            
            ```python
            # Process and normalize to prevent clipping
            loud_signal = [2.0, -3.0, 1.5, -2.5]
            output = processor.process(loud_signal, normalize=True)
            ```
        """
        if not self.is_active:
            raise RuntimeError("Processor not initialized. Call initialize() first.")
        
        if not input_data:
            raise ValueError("Input data cannot be empty")
        
        if gain < 0:
            raise ValueError("Gain must be non-negative")
        
        # Convert to numpy array for processing
        data = np.array(input_data, dtype=np.float64)
        
        # Apply gain
        processed = data * gain
        
        # Optional normalization
        if normalize:
            max_val = np.max(np.abs(processed))
            if max_val > 0:
                processed = processed / max_val
        
        return processed
    
    def get_stats(self) -> Dict[str, Any]:
        """Get processor statistics and current state.
        
        Returns:
            Dictionary containing processor statistics including:
            - sample_rate: Current sample rate
            - buffer_size: Current buffer size  
            - is_active: Whether processor is active
            - buffer_usage: Current buffer utilization percentage
            
        Example:
            ```python
            processor = AudioProcessor(sample_rate=48000)
            processor.initialize()
            
            stats = processor.get_stats()
            print(f"Sample rate: {stats['sample_rate']} Hz")
            print(f"Active: {stats['is_active']}")
            ```
        """
        return {
            'sample_rate': self.sample_rate,
            'buffer_size': self.buffer_size,
            'is_active': self.is_active,
            'buffer_usage': len(self._internal_buffer) / self.buffer_size * 100
        }


def linear_interpolation(x0: float, y0: float, x1: float, y1: float, x: float) -> float:
    """Perform linear interpolation between two points.
    
    This function implements linear interpolation using the formula:
    y = y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    
    Args:
        x0: X coordinate of first point.
        y0: Y coordinate of first point.
        x1: X coordinate of second point.
        y1: Y coordinate of second point.
        x: X coordinate where to interpolate.
        
    Returns:
        Interpolated Y value at position x.
        
    Raises:
        ValueError: If x0 == x1 (undefined interpolation).
        
    Example:
        Interpolate between two audio samples:
        
        ```python
        # Interpolate between sample at time 0 and time 1
        value = linear_interpolation(0.0, 0.5, 1.0, 0.8, 0.3)
        print(f"Interpolated value: {value}")  # 0.59
        ```
        
        Use for sample rate conversion:
        
        ```python
        # Interpolate between adjacent samples
        sample1 = 0.1
        sample2 = 0.3
        fractional_index = 0.75
        
        result = linear_interpolation(0.0, sample1, 1.0, sample2, fractional_index)
        ```
    """
    if x0 == x1:
        raise ValueError("x0 and x1 cannot be equal")
    
    return y0 + (y1 - y0) * (x - x0) / (x1 - x0)


def create_sine_wave(frequency: float, 
                    duration: float, 
                    sample_rate: int = 44100,
                    amplitude: float = 1.0,
                    phase: float = 0.0) -> np.ndarray:
    """Generate a sine wave with specified parameters.
    
    Creates a pure sine wave tone with configurable frequency, duration,
    amplitude and phase offset.
    
    Args:
        frequency: Frequency of the sine wave in Hz.
        duration: Duration of the tone in seconds.
        sample_rate: Sample rate in Hz (default: 44100).
        amplitude: Peak amplitude (default: 1.0).
        phase: Phase offset in radians (default: 0.0).
        
    Returns:
        Generated sine wave as numpy array.
        
    Raises:
        ValueError: If frequency, duration, or sample_rate are non-positive.
        
    Example:
        Generate a 440Hz A note for 1 second:
        
        ```python
        # Standard A4 note
        tone = create_sine_wave(440.0, 1.0)
        
        # Quieter tone with different sample rate
        quiet_tone = create_sine_wave(
            frequency=880.0,
            duration=0.5,
            sample_rate=48000,
            amplitude=0.5
        )
        ```
        
        Generate with phase offset for interesting effects:
        
        ```python
        import math
        
        # Generate two tones 90 degrees out of phase
        tone1 = create_sine_wave(440.0, 1.0, phase=0.0)
        tone2 = create_sine_wave(440.0, 1.0, phase=math.pi/2)
        ```
    """
    if frequency <= 0:
        raise ValueError("Frequency must be positive")
    if duration <= 0:
        raise ValueError("Duration must be positive")
    if sample_rate <= 0:
        raise ValueError("Sample rate must be positive")
    
    # Generate time array
    num_samples = int(duration * sample_rate)
    t = np.linspace(0, duration, num_samples, endpoint=False)
    
    # Generate sine wave
    wave = amplitude * np.sin(2 * np.pi * frequency * t + phase)
    
    return wave


# Module-level constants with documentation
DEFAULT_SAMPLE_RATE: int = 44100
"""Default sample rate used throughout the module (44.1 kHz)."""

MAX_AMPLITUDE: float = 1.0
"""Maximum safe amplitude to prevent clipping."""

SUPPORTED_FORMATS: List[str] = ['wav', 'aiff', 'flac']
"""List of supported audio file formats."""
