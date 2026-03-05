#!/usr/bin/env python
"""Generate window functions and save as a Mojo file."""

import numpy as np

N = 2048
N2 = 16384
PAN_SIZE = 256

# Generate windows
windows = {
    'hann': np.hanning(N).astype(np.float64),
    'hamming': np.hamming(N).astype(np.float64),
    'blackman': np.blackman(N).astype(np.float64),
    'sine': np.sin(np.pi * np.arange(N) / (N - 1)).astype(np.float64),
    'kaiser': np.kaiser(N, beta=14.0).astype(np.float64),
}

# Generate pan2 window (quarter cosine for stereo panning)
pan2_window = []
for i in range(PAN_SIZE):
    angle = (np.pi / 2.0) * i / (PAN_SIZE - 1)
    left = np.cos(angle)
    right = np.cos((np.pi / 2.0) - angle)
    pan2_window.append((left, right))

def generate_sine(n):
    """Generate sine wave."""
    return np.sin(2 * np.pi * np.arange(n) / n)

def generate_triangle(n):
    """Generate triangle wave (naive, not bandlimited)."""
    t = np.arange(n) / n
    return 2 * np.abs(2 * (t - np.floor(t + 0.5))) - 1

def generate_sawtooth(n):
    """Generate sawtooth wave (naive, not bandlimited)."""
    t = np.arange(n) / n
    return 2 * (t - np.floor(t + 0.5))

def generate_square(n):
    """Generate square wave (naive, not bandlimited)."""
    t = np.arange(n) / n
    return np.sign(np.sin(2 * np.pi * t))

def generate_bandlimited_sawtooth(n, num_harmonics):
    """Generate bandlimited sawtooth wave using additive synthesis."""
    result = np.zeros(n)
    for k in range(1, num_harmonics + 1):
        result += ((-1) ** (k + 1)) * np.sin(2 * np.pi * k * np.arange(n) / n) / k
    return result * (2 / np.pi)

def generate_bandlimited_triangle(n, num_harmonics):
    """Generate bandlimited triangle wave using additive synthesis."""
    result = np.zeros(n)
    for k in range(num_harmonics):
        harmonic = 2 * k + 1
        result += ((-1) ** k) * np.sin(2 * np.pi * harmonic * np.arange(n) / n) / (harmonic ** 2)
    return result * (8 / (np.pi ** 2))

def generate_bandlimited_square(n, num_harmonics):
    """Generate bandlimited square wave using additive synthesis."""
    result = np.zeros(n)
    for k in range(num_harmonics):
        harmonic = 2 * k + 1
        result += np.sin(2 * np.pi * harmonic * np.arange(n) / n) / harmonic
    return result * (4 / np.pi)

def write_inline_array(f, name, data, values_per_line=10):
    """Write an InlineArray to the file."""
    f.write(f'comptime {name}: InlineArray[Float64, {len(data)}] = [\n')
    for i in range(0, len(data), values_per_line):
        chunk = data[i:i + values_per_line]
        line = ', '.join(f'{v:.17g}' for v in chunk)
        if i + values_per_line < len(data):
            f.write(f'    {line},\n')
        else:
            f.write(f'    {line}\n')
    f.write(']\n\n')

# Generate all waveforms
waveforms = {
    'sine_wave': generate_sine(N2),
    'triangle_wave': generate_triangle(N2),
    'sawtooth_wave': generate_sawtooth(N2),
    'square_wave': generate_square(N2),
    'bandlimited_sawtooth_wave': generate_bandlimited_sawtooth(N2, 512),
    'bandlimited_triangle_wave': generate_bandlimited_triangle(N2, 256),
    'bandlimited_square_wave': generate_bandlimited_square(N2, 256),
}

# Normalize all waveforms to [-1, 1]
for name, wave in waveforms.items():
    max_val = np.max(np.abs(wave))
    if max_val > 0:
        waveforms[name] = wave / max_val



# Save to Mojo file
with open('mmm_audio/windows_waveforms.mojo', 'w') as f:
    f.write('"""Pre-computed window functions."""\n\n')
    f.write('from collections import List\n\n')
    
    # Write standard windows
    for name, window in windows.items():
        f.write(f'comptime {name}_window: InlineArray[Float64, {len(window)}] = [\n')
        values_per_line = 10
        for i in range(0, len(window), values_per_line):
            chunk = window[i:i + values_per_line]
            line = ', '.join(f'{v:.17g}' for v in chunk)
            if i + values_per_line < len(window):
                f.write(f'    {line},\n')
            else:
                f.write(f'    {line}\n')
        f.write(']\n\n')
    
    # Write pan2 window
    f.write('comptime pan2_window: InlineArray[SIMD[DType.float64, 2], 256] = [\n')
    values_per_line = 5
    for i in range(0, len(pan2_window), values_per_line):
        chunk = pan2_window[i:i + values_per_line]
        line = ', '.join(f'SIMD[DType.float64, 2]({left:.17g}, {right:.17g})' for left, right in chunk)
        if i + values_per_line < len(pan2_window):
            f.write(f'    {line},\n')
        else:
            f.write(f'    {line}\n')
    f.write(']\n')

    f.write('"""Pre-computed waveform lookup tables (16384 samples each)."""\n\n')
    f.write(f'comptime WAVEFORM_SIZE = {N2}\n')
    f.write(f'comptime WAVEFORM_MASK = {N2 - 1}  # For fast modulo with power of 2\n\n')
    
    for name, wave in waveforms.items():
        write_inline_array(f, name, wave.astype(np.float64))


