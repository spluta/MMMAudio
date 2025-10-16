import numpy as np
import math

def linlin(value, in_min, in_max, out_min, out_max):
    """
    Linear-linear transform: map value from input range to output range
    
    Args:
        value: Input value to transform
        in_min, in_max: Input range
        out_min, out_max: Output range
    
    Returns:
        Transformed value in output range
    """
    return out_min + (value - in_min) * (out_max - out_min) / (in_max - in_min)

def linexp(value, in_min, in_max, out_min, out_max):
    """
    Linear-to-exponential transform
    
    Args:
        value: Input value to transform
        in_min, in_max: Input range (linear)
        out_min, out_max: Output range (exponential)
    
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

def lincurve(value, in_min, in_max, out_min, out_max, curve=0):
    """
    Linear-to-curve transform
    
    Args:
        value: Input value to transform
        in_min, in_max: Input range (linear)
        out_min, out_max: Output range
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

def midicps(midi_note):
    """Convert MIDI note number to frequency in Hz"""
    return 440.0 * (2.0 ** ((midi_note - 69.0) / 12.0))

def cpsmidi(frequency):
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