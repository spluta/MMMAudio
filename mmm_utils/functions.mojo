"""
MMMAudioUtility Functions

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
multiple samples simultaneously.
"""

from random import random_float64
from math import log2, log10
from algorithm import vectorize
from sys.info import simdwidthof

# @always_inline
# fn list2SIMD[N: Int = 2](lst: List[Float64]) -> SIMD[DType.float64, N]:
#     """Converts a list to a SIMD vector.

#     This function takes a list of samples and converts it into a SIMD vector
#     of the specified width. If the list has fewer elements than the SIMD width,
#     the remaining elements are filled with zeros. If the list has more elements,
#     only the first 'width' elements are used.

#     Args:
#         lst: The list of samples to convert.
#         width: The desired width of the SIMD vector (default is 1).

#     Returns:
#         A SIMD vector containing the elements from the list.
#     """
#     var simd_vec = SIMD[DType.float64, N](0.0)
#     for i in range(min(len(lst), N)):
#         simd_vec[i] = lst[i]
#     return simd_vec

@always_inline
fn dbamp[width: Int = 1](db: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    """Converts decibel values to amplitude.

    This function converts decibel (dB) values to linear amplitude values.
    The conversion is based on the formula: amplitude = 10^(dB/20).

    Args:
        db: The decibel values to convert.

    Returns:
        The corresponding amplitude values.

    Examples:
        ```
        # Convert a single dB value to amplitude
        db_value = SIMD[DType.float64, 1](6.0)
        amplitude = dbamp(db_value)  # Returns approximately 1.995

        # Convert multiple dB values simultaneously
        db_values = SIMD[DType.float64, 4](0.0, -6.0, -12.0, -24.0)
        amplitudes = dbamp[4](db_values)  # Returns approximately [1.0, 0.501, 0.251, 0.063]
        ```
    """
    return 10.0 ** (db / 20.0)

@always_inline
fn ampdb[width: Int = 1](amp: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    """Converts amplitude values to decibels.

    This function converts linear amplitude values to decibel (dB) values.
    The conversion is based on the formula: dB = 20 * log10(amplitude).

    Args:
        amp: The amplitude values to convert.

    Returns:
        The corresponding decibel values.

    Examples:
        ```
        # Convert a single amplitude value to dB
        amp_value = SIMD[DType.float64, 1](1.0)
        db_value = ampdb(amp_value)  # Returns 0.0

        # Convert multiple amplitude values simultaneously
        amp_values = SIMD[DType.float64, 4](1.0, 0.5, 0.25, 0.1)
        db_values = ampdb[4](amp_values)  # Returns [0.0, -6.0206, -12.0412, -20.0000]
        ```
    """
    return 20.0 * log10(amp)

@always_inline
fn select[dtype: DType, width: Int](index: SIMD[dtype, width], list: List[SIMD[dtype, width]]) -> SIMD[dtype, width]:
    index_int = Int(index) % len(list)
    index_mix = index - index_int
    val = list[index_int] * (1.0 - index_mix) + list[(index_int + 1) % len(list)] * index_mix
    return val

@always_inline
fn linlin[
    dtype: DType, width: Int, //
](input: SIMD[dtype, width], in_min: SIMD[dtype, width], in_max: SIMD[dtype, width], out_min: SIMD[dtype, width], out_max: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """Maps samples from one range to another range linearly.

    This function performs linear mapping from an input range to an output range.
    samples outside the input range are clamped to the corresponding output boundaries.
    This is commonly used for scaling control samples, normalizing data, and 
    converting between different parameter ranges.

    Args:
        input: The samples to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range.
        out_max: The maximum of the output range.

    Examples:
        ```
        # Map MIDI velocity (0-127) to gain (0.0-1.0)
        velocity = SIMD[DType.float64, 1](64.0)
        gain = linlin(velocity, 0.0, 127.0, 0.0, 1.0)  # Returns 0.504
        
        # Map multiple control samples simultaneously
        controls = SIMD[DType.float64, 4](0.25, 0.5, 0.75, 1.0)
        frequencies = linlin[4](controls, 0.0, 1.0, 20.0, 20000.0)
        
        # Invert a normalized range
        normal_vals = SIMD[DType.float64, 2](0.3, 0.7)
        inverted = linlin[2](normal_vals, 0.0, 1.0, 1.0, 0.0)
        ```
    """
    output = input

    # Create masks for the conditions
    below_min: SIMD[DType.bool, width] = output.lt(in_min)
    above_max: SIMD[DType.bool, width] = output.gt(in_max)

    scaled = (input - in_min) / (in_max - in_min) * (out_max - out_min) + out_min

    # Use select to choose the right value based on conditions
    return below_min.select(out_min,
       above_max.select(out_max, scaled))

@always_inline
fn linexp[width: Int, //
](input: SIMD[DType.float64, width], in_min: SIMD[DType.float64, width], in_max: SIMD[DType.float64, width], out_min: SIMD[DType.float64, width], out_max: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    """Maps samples from one linear range to another exponential range.

    This function performs exponential mapping from a linear input range to an
    exponential output range. This is essential for musical applications where
    frequency perception is logarithmic. Both output range samples must be positive.

    Args:
        input: The samples to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range (must be > 0).
        out_max: The maximum of the output range (must be > 0).

    Returns:
        The exponentially mapped samples in the output range.

    Examples:
        ```
        # Map linear slider (0-1) to frequency range (20Hz-20kHz)
        slider_pos = SIMD[DType.float64, 1](0.5)
        frequency = linexp(slider_pos, 0.0, 1.0, 20.0, 20000.0)  # ≈ 632 Hz
        
        # Map MIDI controller to filter cutoff frequencies
        cc_samples = SIMD[DType.float64, 4](0.0, 0.33, 0.66, 1.0)
        cutoffs = linexp[4](cc_samples, 0.0, 1.0, 100.0, 10000.0)
        
        # Create exponential envelope shape
        linear_time = SIMD[DType.float64, 1](0.8)
        exp_amplitude = linexp(linear_time, 0.0, 1.0, 0.001, 1.0)
        ```
    """
    below_min: SIMD[DType.bool, width] = input.lt(in_min)
    above_max: SIMD[DType.bool, width] = input.gt(in_max)
    normalized = (input - in_min) / (in_max - in_min)
    exponential_scaled = out_min * pow(out_max / out_min, normalized)

    return below_min.select(out_min,
        above_max.select(out_max, exponential_scaled))
    # # Create condition masks
    # below_min: SIMD[DType.bool, width] = input < in_min
    # above_max: SIMD[DType.bool, width] = input > in_max

    # # Safety checks
    # zero_range: SIMD[DType.bool, width] = in_max == in_min
    # zero_out_min: SIMD[DType.bool, width] = out_min == 0.0

    # # Compute normalized values (safe division)
    # safe_in_range = zero_range.select(1, in_max - in_min)
    # normalized = (input - in_min) / safe_in_range

    # # Compute exponential scaling with safety for out_min = 0
    # safe_out_min = zero_out_min.select(0.001, out_min)
    # ratio = out_max / safe_out_min
    # exponential_scaled = zero_out_min.select( 
    #                             out_max * normalized,  # Linear fallback when out_min = 0
    #                             out_min * pow(ratio, normalized))

    # # Handle zero range case (use out_min when range is zero)
    # final_scaled = zero_range.select(out_min, exponential_scaled)

    # # Apply all conditions
    # result = below_min.select(out_min,
    #             above_max.select(out_max, final_scaled))

    # return result

@always_inline
fn lincurve[width: Int, //
](input: SIMD[DType.float64, width], in_min: SIMD[DType.float64, width], in_max: SIMD[DType.float64, width], out_min: SIMD[DType.float64, width], out_max: SIMD[DType.float64, width], curve: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    """Maps samples from one linear range to another curved range.

    This function performs curved mapping from a linear input range to a
    curved output range. The curve is exponential in nature, providing a smooth
    transition between values.

    Args:
        input: The samples to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range (must be > 0).
        out_max: The maximum of the output range (must be > 0).

    Returns:
        The curved mapped samples in the output range.

    Examples:
        ```
        # Map linear slider (0-1) to frequency range (20Hz-20kHz)
        slider_pos = SIMD[DType.float64, 1](0.5)
        frequency = lincurve(slider_pos, 0.0, 1.0, 20.0, 20000.0)  # ≈ 632 Hz

        # Map MIDI controller to filter cutoff frequencies
        cc_samples = SIMD[DType.float64, 4](0.0, 0.33, 0.66, 1.0)
        cutoffs = lincurve[4](cc_samples, 0.0, 1.0, 100.0, 10000.0)

        # Create curved envelope shape
        linear_time = SIMD[DType.float64, 1](0.8)
        curved_amplitude = lincurve(linear_time, 0.0, 1.0, 0.001, 1.0)
        ```
    """
    # Handle zero curve values to avoid NaN
    curve_zero: SIMD[DType.bool, width] = curve == 0.0
    temp_curve: SIMD[DType.float64, width] = curve_zero.select(0.0001, curve)

    # Create condition masks
    below_min: SIMD[DType.bool, width] = input.lt(in_min)
    above_max: SIMD[DType.bool, width] = input.gt(in_max)

    # Compute exponential curve parameters for all elements
    grow = pow(SIMD[DType.float64, width](2.71828182845904523536), temp_curve)  # e^curve
    a = (out_max - out_min) / (1.0 - grow)
    b = out_min + a

    # Scale input to 0-1 range
    scaled = (input - in_min) / (in_max - in_min)

    # Apply exponential curve
    curved_result = b - (a * pow(grow, scaled))

    # Use select to choose the right value based on conditions
    result = below_min.select(out_min,
                above_max.select(out_max, curved_result))

    return result


@always_inline
fn clip[
    dtype: DType, width: Int, //
](x: SIMD[dtype, width], lo: SIMD[dtype, width], hi: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """Clips each element in the SIMD vector to the specified range.

    Args:
        x: The SIMD vector to clip. Each element will be clipped individually.
        lo: The minimum sample.
        hi: The maximum sample.

    Returns:
        The clipped SIMD vector.
    """ 
    return min(max(x, lo), hi)

@always_inline
fn wrap[
    dtype: DType, width: Int, //
](input: SIMD[dtype, width], min_val: SIMD[dtype, width], max_val: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """Wraps a sample around a specified range.

    Args:
        input: The sample to wrap.
        min_val: The minimum of the range.
        max_val: The maximum of the range.

    Returns:
        The wrapped sample within the range [min_val, max_val]. Returns the sample if min_val >= max_val.
    """
    # Check if any min_val >= max_val (vectorized comparison)
    var invalid_range: SIMD[DType.bool, width] = min_val >= max_val
    
    var range_size = max_val - min_val
    var wrapped_sample = (input - min_val) % range_size + min_val
    
    # Handle negative modulo results (vectorized)
    var needs_adjustment: SIMD[DType.bool, width] = wrapped_sample.lt(min_val)

    wrapped_sample = needs_adjustment.select(wrapped_sample + range_size, wrapped_sample)

    # Return original input where range is invalid, wrapped result otherwise
    return invalid_range.select(input, wrapped_sample)

@always_inline
fn quadratic_interp[
    dtype: DType, width: Int, //
](y0: SIMD[dtype, width], y1: SIMD[dtype, width], y2: SIMD[dtype, width], x: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """Performs quadratic interpolation between three points.
    
    Args:
        y0: The sample at position 0.
        y1: The sample at position 1.
        y2: The sample at position 2.
        x: The interpolation position (typically between 0 and 2).

    Returns:
        The interpolated sample at position x.
    """
    # Calculate the coefficients of the quadratic polynomial
    xm1 = x - 1.0
    xm2 = x - 2.0

    # Compute Lagrange coefficients for all elements
    coeff0 = (xm1 * xm2) * 0.5
    coeff1 = (x * xm2) * (-1.0)  
    coeff2 = (x * xm1) * 0.5

    # Apply coefficients to y samples and sum
    out = coeff0 * y0 + coeff1 * y1 + coeff2 * y2

    return out

@always_inline
fn cubic_interp[
    dtype: DType, width: Int, //
](p0: SIMD[dtype, width], p1: SIMD[dtype, width], p2: SIMD[dtype, width], p3: SIMD[dtype, width], t: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """
    Performs cubic interpolation between.

    Cubic Intepolation equation from *The Audio Programming Book* 
    by Richard Boulanger and Victor Lazzarini. pg. 400
    
    Args:
        p0: Point to the left of p1.
        p1: Point to the left of the float t.
        p2: Point to the right of the float t.
        p3: Point to the right of p2.
        t: Interpolation parameter (0.0 to 1.0).
    
    Returns:
        Interpolated sample.
    """
    return p1 + (((p3 - p0 - 3*p2 + 3*p1)*t + 3*(p2 + p0 - 2*p1))*t - (p3 + 2*p0 - 6*p2 + 3*p1))*t / 6.0


# this is
@always_inline
fn lagrange4[
    dtype: DType, width: Int, //
](sample0: SIMD[dtype, width], sample1: SIMD[dtype, width], sample2: SIMD[dtype, width], sample3: SIMD[dtype, width], sample4: SIMD[dtype, width], frac: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """
    Perform Lagrange interpolation for 4th order case (from JOS Faust Model). This is extrapolated from the JOS Faust filter model.

    lagrange4[width](sample0, sample1, sample2, sample3, sample4, frac) -> SIMD[dtype, width]

    Args:
        sample0: The first sample.
        sample1: The second sample.
        sample2: The third sample.
        sample3: The fourth sample.
        sample4: The fifth sample.
        frac: The fractional delay (0.0 to 1.0) which is the location between sample0 and sample1.

    Returns:
        The interpolated sample.
    """

    var o = 1.49999 + frac
    var fd = o + frac

    # simd optimized!
    var out: SIMD[dtype, width] = SIMD[dtype, width](0.0)

    var fdm1: SIMD[dtype, width] = SIMD[dtype, width](0.0)
    var fdm2: SIMD[dtype, width] = SIMD[dtype, width](0.0)
    var fdm3: SIMD[dtype, width] = SIMD[dtype, width](0.0)
    var fdm4: SIMD[dtype, width] = SIMD[dtype, width](0.0)

    offsets = SIMD[dtype, 4](1.0, 2.0, 3.0, 4.0)

    for i in range(width):
        var fd_vec = SIMD[dtype, 4](fd[i], fd[i], fd[i], fd[i])

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

    for i in range(width):
        coeffs: SIMD[dtype, 4] = SIMD[dtype, 4](coeff0[i], coeff1[i], coeff2[i], coeff3[i])

        samples_simd = SIMD[dtype, 4](
            sample0[i],
            sample1[i],
            sample2[i],
            sample3[i]
        )

        var products = samples_simd * coeffs

        out[i] = products.reduce_add() + sample4[i] * coeff4[i]

    return out
    
@always_inline
fn lerp[
    dtype: DType, width: Int, //
](p0: SIMD[dtype, width], p1: SIMD[dtype, width], t: SIMD[dtype, width]) -> SIMD[dtype, width]:
    """
    Performs linear interpolation between two points.
    
    Parameters:
        N: Size of the SIMD vector - defaults to 1.

    Args:
        p0: The starting point.
        p1: The ending point.
        t: The interpolation parameter (0.0 to 1.0).
    
    Returns:
        The interpolated sample.
    """
    
    return p0 + (p1 - p0) * t

@always_inline
fn midicps[
    width: Int, //
](midi_note_number: SIMD[DType.float64, width], reference_midi_note: Float64 = 69, reference_frequency: Float64 = 440.0) -> SIMD[DType.float64, width]:
    frequency = Float64(reference_frequency) * 2.0 ** ((midi_note_number - reference_midi_note) / 12.0)
    return frequency

@always_inline
fn cpsmidi[
    width: Int, //
](freq: SIMD[DType.float64, width], reference_midi_note: Float64 = 69.0, reference_frequency: Float64 = 440.0) -> SIMD[DType.float64, width]:
    n = 12.0 * log2(freq / reference_frequency) + reference_midi_note
    return n

@always_inline
fn sanitize[
    width: Int, //
](mut x: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    var absx = abs(x)
    too_large: SIMD[DType.bool, width] = absx.gt(SIMD[DType.float64, width](1e15))
    too_small: SIMD[DType.bool, width] = absx.lt(SIMD[DType.float64, width](1e-15))
    should_zero: SIMD[DType.bool, width] = too_large | too_small

    return should_zero.select(0.0, x)

fn random_lin_float64[N: Int = 1](min: SIMD[DType.float64, N], max: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """
    Generates a random float64 sample from a linear distribution.

    Parameters:
        N: Size of the SIMD vector - defaults to 1.

    Args:
        min: The minimum sample (inclusive).
        max: The maximum sample (inclusive).
    Returns:
        A random float64 sample from the specified range.
    """
    var u = SIMD[DType.float64, N](0.0)
    @parameter
    for i in range(N):
        u[i] = random_float64(min[i], max[i])
    return u

@always_inline
fn random_exp_float64[N: Int = 1](min: SIMD[DType.float64, N], max: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
    """
    Generates a random float64 sample from an exponential distribution.

    Parameters:
        N: Size of the SIMD vector - defaults to 1.

    Args:
        min: The minimum sample (inclusive).
        max: The maximum sample (inclusive).
    Returns:
        A random float64 sample from the specified range.
    """
    var u = SIMD[DType.float64, N](0.0)
    @parameter
    for i in range(N):
        u[i] = random_float64()
    u = linexp(u, 0.0, 1.0, min, max)
    return u