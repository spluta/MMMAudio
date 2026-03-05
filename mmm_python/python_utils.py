import numpy as np
import math
import random

def linlin(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
    """
    Linear-linear transform: map value from input range to output range
    
    Args:
        value: Input value to transform
        in_min: Minimum of input range
        in_max: Maximum of input range
        out_min: Minimum of output range
        out_max: Maximum of output range
    
    Returns:
        Transformed value in output range
    """
    return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)

def linexp(value: float, in_min: float, in_max: float, out_min: float, out_max: float) -> float:
    """
    Linear-to-exponential transform
    
    Args:
        value: Input value to transform
        in_min: Minimum of input range (linear)
        in_max: Maximum of input range (linear)
        out_min: Minimum of output range (exponential)
        out_max: Maximum of output range (exponential)
    
    Returns:
        Exponentially scaled output value
    """
    if out_min <= 0 or out_max <= 0:
        raise ValueError("Output range must be positive for exponential scaling")
    
    # Normalize input to 0-1 range
    normalized = (value - in_min) / (in_max - in_min)
    
    # Apply exponential scaling
    ratio = out_max / out_min
    result = out_min * (ratio ** normalized)
    
    return result

def lincurve(value: float, in_min: float, in_max: float, out_min: float, out_max: float, curve: float = 0) -> float:
    """
    Linear-to-curve transform
    
    Args:
        value: Input value to transform
        in_min: Minimum of input range (linear)
        in_max: Maximum of input range (linear)
        out_min: Minimum of output range
        out_max: Maximum of output range
        curve: Curve parameter
               curve = 0: linear
               curve > 0: exponential-like (steep at end)
               curve < 0: logarithmic-like (steep at start)
    
    Returns:
        Curved output value
    """
    # Normalize input to 0-1 range
    normalized = (value - in_min) / (in_max - in_min)
    
    if curve == 0:
        # Linear case
        curved = normalized
    else:
        # Apply curve transformation
        if curve > 0:
            # Exponential-like curve
            curved = (np.exp(curve * normalized) - 1) / (np.exp(curve) - 1)
        else:
            # Logarithmic-like curve (curve < 0)
            curved = np.log(1 + abs(curve) * normalized) / np.log(1 + abs(curve))
    
    # Map to output range
    result = out_min + curved * (out_max - out_min)
    return result

def midicps(midi_note: float) -> float:
    """Convert MIDI note number to frequency in Hz
    
    Args:
        midi_note: MIDI note number

    Returns:
        Frequency in Hz
    """
    return 440.0 * (2.0 ** ((midi_note - 69.0) / 12.0))

def cpsmidi(frequency: float) -> float:
    """Convert frequency in Hz to MIDI note number
    
    Args:
        frequency: Frequency in Hz

    Returns:
        MIDI note number
    """
    return 69.0 + 12 * math.log2(frequency / 440.0)

def clip(val: float, min_val: float, max_val: float) -> float:
    """Clip a value to be within a specified range.
    
    Args:
        val: The value to clip.
        min_val: The minimum allowable value.
        max_val: The maximum allowable value.
    
    Returns:
        The clipped value.
    """
    return max(min_val, min(max_val, val))

def ampdb(amp: float) -> float:
    """Convert amplitude to decibels.
    
    Args:
        amp: Amplitude value.

    Returns:    
        Decibel value.
    """
    if amp <= 0:
        return -float('inf')  # Return negative infinity for zero or negative amplitude
    return 20.0 * np.log10(amp)

def polar_to_complex(mags: np.ndarray, phases: np.ndarray) -> np.ndarray:
    """
    Convert polar coordinates (magnitude and phase) to complex numbers.
    
    Args:
        mags: Magnitude spectrum (numpy array)
        phases: Phase spectrum (numpy array)
    
    Returns:
        complex_signal: Complex representation (numpy array)
    """
    complex_signal = mags * np.exp(1j * phases)
    return complex_signal

def rrand(min_val: float, max_val: float) -> float:
    """Generate a random float between min_val and max_val.
    
    Args:
        min_val: Minimum value.
        max_val: Maximum value.
    Returns:
        Random float between min_val and max_val.
    """
    return random.uniform(min_val, max_val)

def exprand(min_val: float, max_val: float) -> float:
    """Generate a random float from an exponential distribution with given lambda.
    
    Args:
        min_val: Minimum value.
        max_val: Maximum value.

    """
    return linexp(random.uniform(0.0, 1.0), 0.0, 1.0, min_val, max_val)

