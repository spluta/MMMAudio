import numpy as np

def polar_to_complex(mags: np.ndarray, phases: np.ndarray):
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