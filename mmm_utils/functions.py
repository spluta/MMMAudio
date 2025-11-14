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
    """Convert MIDI note number to frequency in Hz"""
    return 440.0 * (2.0 ** ((midi_note - 69.0) / 12.0))

def cpsmidi(frequency: float) -> float:
    """Convert frequency in Hz to MIDI note number"""
    return 69.0 + 12 * math.log2(frequency / 440.0)

def scale(val: float = 0, in_min: float = 0, in_max: float = 1, out_min: float = 0, out_max: float = 1) -> float:
    """Scale a value from one range to another."""
    in_range = in_max - in_min
    norm_val = (val - in_min) / in_range if in_range != 0 else 0
    out_range = out_max - out_min
    scaled_val = (norm_val * out_range) + out_min
    return scaled_val

def clip(val: float, min_val: float, max_val: float) -> float:
    """Clip a value to be within a specified range."""
    return max(min_val, min(max_val, val))
