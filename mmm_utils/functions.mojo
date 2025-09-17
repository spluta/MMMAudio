"""
MMM Utility Functions

This module provides essential utility functions for audio processing and mathematical
operations in the MMMAudio framework. All functions are optimized for SIMD operations
to achieve maximum performance on modern processors.

The functions in this module include:
- Range mapping functions (linear and exponential)
- Clipping and wrapping utilities
- Interpolation algorithms
- MIDI/frequency conversion
- Audio utility functions
- Random number generation

All functions support vectorized operations through SIMD types for processing
multiple values simultaneously.
"""

from random import random_float64
from math import log2
from algorithm import vectorize
from sys.info import simdwidthof

fn linlin[N: Int = 1](value: SIMD[DType.float64, N], in_min: SIMD[DType.float64, N], in_max: SIMD[DType.float64, N], out_min: SIMD[DType.float64, N], out_max: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """Maps values from one range to another range linearly.

    This function performs linear mapping from an input range to an output range.
    Values outside the input range are clamped to the corresponding output boundaries.
    This is commonly used for scaling control values, normalizing data, and 
    converting between different parameter ranges.

    Parameters:
        N: Size of the SIMD vector (defaults to 1).

    Args:
        value: The values to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range.
        out_max: The maximum of the output range.

    Returns:
        The linearly mapped values in the output range.

    Examples:
        # Map MIDI velocity (0-127) to gain (0.0-1.0)
        velocity = SIMD[DType.float64, 1](64.0)
        gain = linlin(velocity, 0.0, 127.0, 0.0, 1.0)  # Returns 0.504
        
        # Map multiple control values simultaneously
        controls = SIMD[DType.float64, 4](0.25, 0.5, 0.75, 1.0)
        frequencies = linlin[4](controls, 0.0, 1.0, 20.0, 20000.0)
        
        # Invert a normalized range
        normal_vals = SIMD[DType.float64, 2](0.3, 0.7)
        inverted = linlin[2](normal_vals, 0.0, 1.0, 1.0, 0.0)
    """
    var result = SIMD[DType.float64, N](0.0)
    for i in range(N):
        if value[i] < in_min[i]:
            result[i] = out_min[i]
        elif value[i] > in_max[i]:
            result[i] = out_max[i]
        else:
            # First scale to 0..1 range, then scale to output range
            var normalized = (value[i] - in_min[i]) / (in_max[i] - in_min[i])
            result[i] = normalized * (out_max[i] - out_min[i]) + out_min[i]
    return result

fn linexp[N: Int = 1](value: SIMD[DType.float64, N], in_min: SIMD[DType.float64, N], in_max: SIMD[DType.float64, N], out_min: SIMD[DType.float64, N], out_max: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """Maps values from one linear range to another exponential range.

    This function performs exponential mapping from a linear input range to an
    exponential output range. This is essential for musical applications where
    frequency perception is logarithmic. Both output range values must be positive.

    Parameters:
        N: Size of the SIMD vector (defaults to 1).

    Args:
        value: The values to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range (must be > 0).
        out_max: The maximum of the output range (must be > 0).

    Returns:
        The exponentially mapped values in the output range.

    Examples:
        # Map linear slider (0-1) to frequency range (20Hz-20kHz)
        slider_pos = SIMD[DType.float64, 1](0.5)
        frequency = linexp(slider_pos, 0.0, 1.0, 20.0, 20000.0)  # ≈ 632 Hz
        
        # Map MIDI controller to filter cutoff frequencies
        cc_values = SIMD[DType.float64, 4](0.0, 0.33, 0.66, 1.0)
        cutoffs = linexp[4](cc_values, 0.0, 1.0, 100.0, 10000.0)
        
        # Create exponential envelope shape
        linear_time = SIMD[DType.float64, 1](0.8)
        exp_amplitude = linexp(linear_time, 0.0, 1.0, 0.001, 1.0)
    """
    var result = SIMD[DType.float64, N](0.0)
    for i in range(N):
        if value[i] < in_min[i]:
            result[i] = out_min[i]
        elif value[i] > in_max[i]:
            result[i] = out_max[i]
        else:
            # First scale to 0..1 range linearly, then apply exponential scaling
            var normalized = (value[i] - in_min[i]) / (in_max[i] - in_min[i])
            result[i] = out_min[i] * pow(out_max[i] / out_min[i], normalized)
    return result


fn clip[N: Int = 1](val: SIMD[DType.float64, N], lo: SIMD[DType.float64, N], hi: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """Clips each element in the SIMD vector to the specified range.
    Parameters:
        N: size of the SIMD vector - defaults to 1
    Args:
        val: The SIMD vector to clip. Each element will be clipped individually.
        lo: The minimum value.
        hi: The maximum value.
    Returns:
        The clipped SIMD vector.
    """

    var val2 = val
    for i in range(N):
        if val2[i] < lo[i]:
            val2[i] = lo[i]
        elif val2[i] > hi[i]:
            val2[i] = hi[i]
    return val2

# fn clip(mut lst: List[Float64], lo: Float64, hi: Float64) -> None:
#     """Clips each element in the list to the specified range."""
#     for i in range(len(lst)):
#         if lst[i] < lo:
#             lst[i] = lo
#         elif lst[i] > hi:
#             lst[i] = hi

fn wrap[N: Int=1](value: SIMD[DType.float64, N], min_val: SIMD[DType.float64, N], max_val: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """Wraps a value around a specified range.
    Parameters:
        N: size of the SIMD vector - defaults to 1

    Args:
        value: The value to wrap
        min_val: The minimum of the range
        max_val: The maximum of the range
    Returns:
        The wrapped value within the range [min_val, max_val]
    """
    var range_size = max_val - min_val
    if range_size <= 0:
        return min_val  # If the range is invalid, return the minimum value
    var wrapped_value = (value - min_val) % range_size + min_val
    if wrapped_value < min_val:
        wrapped_value += range_size  # Ensure the value is within the range
    return wrapped_value

fn wrap[N: Int=1](value: SIMD[DType.int64, N], min_val: SIMD[DType.int64, N], max_val: SIMD[DType.int64, N]) -> SIMD[DType.int64, N]:
    """
    Wraps a value around a specified range.
    
    Parameters:
        N: size of the SIMD vector - defaults to 1

    Args:
        value: The value to wrap
        min_val: The minimum of the range
        max_val: The maximum of the range
    Returns:
        The wrapped value within the range [min_val, max_val]
    """
    var range_size = max_val - min_val
    if range_size <= 0:
        return min_val  # If the range is invalid, return the minimum value
    var wrapped_value = (value - min_val) % range_size + min_val
    if wrapped_value < min_val:
        wrapped_value += range_size  # Ensure the value is within the range
    return wrapped_value

fn quadratic_interp(y0: Float64, y1: Float64, y2: Float64, x: Float64) -> Float64:
    """Performs quadratic interpolation between three points.
    
    Args:
        y0: The value at position 0
        y1: The value at position 1
        y2: The value at position 2
        x: The interpolation position (typically between 0 and 2)
        
    Returns:
        The interpolated value at position x
    """
    # Calculate the coefficients of the quadratic polynomial
    var xm1 = x - 1.0
    var xm2 = x - 2.0
    var y_values = SIMD[DType.float64, 4](y0, y1, y2, 0.0)
    var coeffs = SIMD[DType.float64, 4](
        (xm1 * xm2) * 0.5,
        (x * xm2) * (-1.0),
        (x * xm1) * 0.5,
        0.0
        )
    var prod = y_values * coeffs

    # Return the estimated value
    return prod[0] + prod[1] + prod[2]

fn cubic_interp(p0: Float64, p1: Float64, p2: Float64, p3: Float64, t: Float64) -> Float64:
    """
    Performs cubic interpolation between.

    Cubic Intepolation equation from *The Audio Programming Book* 
    by Richard Boulanger and Victor Lazzarini. pg. 400
    
    Args:
        p0: point to th left of p1
        p1: point to the left of the float t
        p2: point to the right of the float t
        p3: point to the right of p2
        t: Interpolation parameter (0.0 to 1.0)
    
    Returns:
        Interpolated value
    """
    return p1 + (((p3 - p0 - 3*p2 + 3*p1)*t + 3*(p2 + p0 - 2*p1))*t - (p3 + 2*p0 - 6*p2 + 3*p1))*t / 6.0


# this is
fn lagrange4[N: Int = 1](sample0: SIMD[DType.float64, N], sample1: SIMD[DType.float64, N], sample2: SIMD[DType.float64, N], sample3: SIMD[DType.float64, N], sample4: SIMD[DType.float64, N], frac: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """
    Perform Lagrange interpolation for 4th order case (from JOS Faust Model). This is extrapolated from the JOS Faust filter model.
    
    lagrange4[N](sample0, sample1, sample2, sample3, sample4, frac) -> SIMD[Float64, N]

    Parameters:
        N: size of the SIMD vector - defaults to 1

    Args:
        sample0: The first sample
        sample1: The second sample
        sample2: The third sample
        sample3: The fourth sample
        sample4: The fifth sample
        frac: The fractional delay (0.0 to 1.0) which is the location between sample0 and sample1

    Returns:
        The interpolated value
    """

    var o = 1.49999 + frac
    var fd = o + frac

    # simd optimized!
    var out: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0)

    var fdm1: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0)
    var fdm2: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0)
    var fdm3: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0)
    var fdm4: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0)

    offsets = SIMD[DType.float64, 4](1.0, 2.0, 3.0, 4.0)

    for i in range(N):
        var fd_vec = SIMD[DType.float64, 4](fd[i], fd[i], fd[i], fd[i])

        var fd_minus_offsets = fd_vec - offsets  # [fd-1, fd-2, fd-3, fd-4]

        fdm1[i] = fd_minus_offsets[0]
        fdm2[i] = fd_minus_offsets[1]
        fdm3[i] = fd_minus_offsets[2]
        fdm4[i] = fd_minus_offsets[3]

    # all this math is parallelized - for N > 4, this should be further optimized
    var coeff0 = fdm1 * fdm2 * fdm3 * fdm4 / 24.0
    var coeff1 = (0.0 - fd) * fdm2 * fdm3 * fdm4 / 6.0
    var coeff2 = fd * fdm1 * fdm3 * fdm4 / 4.0
    var coeff3 = (0.0 - fd * fdm1 * fdm2 * fdm4) / 6.0
    var coeff4 = fd * fdm1 * fdm2 * fdm3 / 24.0

    for i in range(N):
        coeffs: SIMD[DType.float64, 4] = SIMD[DType.float64, 4](coeff0[i], coeff1[i], coeff2[i], coeff3[i])

        samples_simd = SIMD[DType.float64, 4](
            sample0[i],
            sample1[i],
            sample2[i],
            sample3[i]
        )

        var products = samples_simd * coeffs

        out[i] = products[0] + products[1] + products[2] + products[3] + sample4[i] * coeff4[i]

    return out

fn lerp[N: Int = 1](p0: SIMD[DType.float64, N], p1: SIMD[DType.float64, N], t: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """
    Performs linear interpolation between two points.
    
    lerp[N](p0, p1, t) -> Float64 or SIMD[Float64, N]

    Parameters:
        N: size of the SIMD vector - defaults to 1

    Args:
        p0: The starting point
        p1: The ending point
        t: The interpolation parameter (0.0 to 1.0)
        curve: The curve parameter (0.0 for linear, 1.0 for exponential)
    Returns:
        The interpolated value
    """
    
    return p0 + (p1 - p0) * t

fn midicps(midi_note_number: Int64, reference_midi_note: Int64 = 69, reference_frequency: Float64 = 440.0) -> Float64:
    frequency = Float64(reference_frequency) * 2.0 ** (Float64(midi_note_number - reference_midi_note) / 12.0)
    return frequency

fn midicps(midi_note_number: Float64, reference_midi_note: Float64 = 69.0, reference_frequency: Float64 = 440.0) -> Float64:
    frequency = Float64(reference_frequency) * 2.0 ** ((midi_note_number - reference_midi_note) / 12.0)
    return frequency

fn cpsmidi(freq: Float64, reference_midi_note: Float64 = 69.0, reference_frequency: Float64 = 440.0) -> Float64:
    n = 12.0 * log2(freq / reference_frequency) + reference_midi_note
    return n

fn mix(mut output: List[Float64], *lists: List[Float64]) -> None:
    for lst in lists:
        for i in range(len(output)):
            if i < len(lst):
                output[i] += lst[i]  # Sum the samples

fn sanitize[N: Int = 1](x: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        var absx = abs(x)
        # Avoid NaN or Inf values
        safe = True
        for i in range(N):
            if absx[i] > 1e15 or absx[i] < 1e-15:
                safe = False
                break
        return x if safe else 0.0


fn random_exp_float64[N: Int = 1](min: SIMD[DType.float64, N], max: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """
    Generates a random float64 value from an exponential distribution.

    Parameters:
        N: size of the SIMD vector - defaults to 1

    Args:
        min: The minimum value (inclusive).
        max: The maximum value (inclusive).
    Returns:
        A random float64 value from the specified range.
    """
    var u = SIMD[DType.float64, N](0.0)
    for i in range(N):
        u[i] = linexp(random_float64(), 0.0, 1.0, min[i], max[i])
    return u



# fn zero(mut lst: List[Float64]) -> None:
#     """Sets all elements of the list to zero."""
#     for i in range(len(lst)):
#         lst[i] = 0.0  # Set each element to zero

# fn mix_vectorized(mut output: List[Float64], *lists: List[Float64]) -> None:
#     alias simd_width = simdwidthof[DType.float64]()
#     var size = len(output)
#     for lst in lists:
#         var lst_size = len(lst)
#         var simd_end = lst_size - (lst_size % simd_width)
#         @parameter
#         fn closure[width: Int](i: Int):
#             var out_vec = output.load[width](i)
#             var in_vec = lst.load[width](i)
#             output.store[width](i, out_vec + in_vec)
#         # Vectorized loop for the part that fits SIMD width
#         vectorize[closure, simd_width](simd_end)
#         # Scalar loop for the remainder and for indices beyond lst_size
#         for i in range(simd_end, size):
#             if i < lst_size:
#                 output[i] += lst[i]

# fn mix(mut output: List[Float64], *samples: Float64) -> None:
#     for i in range(len(output)):
#         if i < len(samples):
#             output[i] += samples[i]  # Sum the samples

# fn mix(input: List[List[Float64]]) -> List[Float64]:
#     var output = List[Float64]()
#     for _ in range(len(input[0])):
#         output.append(0.0)  # Initialize output list with zeros
#     for lst in input:
#         for i in range(len(output)):
#             if i < len(lst):
#                 output[i] += lst[i]
#     return output

# fn mul(mut output: List[Float64], factor: Float64):
#     """Multiplies each element in the output list by a factor."""
#     for i in range(len(output)):
#         output[i] *= factor  # Multiply each sample by the factor

# fn mul(output: List[Float64], factor: Float64) -> List[Float64]:
#     """Returns a new list with each element multiplied by the factor."""
#     var result = List[Float64](len(output), 0.0)
#     for i in range(len(output)):
#         result[i] = output[i] * factor  # Multiply each sample by the factor
#     return result

# q
# not yet tested
# fn mul_vectorized(mut output: List[Float64], factor: Float64):
#     alias simd_width = simdwidthof[DType.float64]()
#     var size = len(output)
#     @parameter
#     fn closure[width: Int](i: Int):
#         # Load a SIMD vector from output, multiply by factor, and store back
#         var vec = output.load[width](i)
#         var result = vec * SIMD[DType.float64, width](factor)
#         output.store[width](i, result)
#     vectorize[closure, simd_width](size)