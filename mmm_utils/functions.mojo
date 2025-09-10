from random import random_float64
from math import log2
from algorithm import vectorize
from sys.info import simdwidthof

fn linlin(value: Float64, in_min: Float64, in_max: Float64, out_min: Float64, out_max: Float64) -> Float64:
    """Maps a value from one range to another range.

    Args:
        value: The value to map.
        in_min: The minimum of the input range..
        in_max: The maximum of the input range.
        out_min: The minimum of the output range.
        out_max: The maximum of the output range.

    Returns:
        The mapped value in the output range.
    """
    if value < in_min:
        return out_min
    elif value > in_max:
        return out_max
    # First scale to 0..1 range, then scale to output range
    var normalized = (value - in_min) / (in_max - in_min)
    return normalized * (out_max - out_min) + out_min

fn linexp(value: Float64, in_min: Float64, in_max: Float64, out_min: Float64, out_max: Float64) -> Float64:
    """Maps a value from one linear range to another exponential range.

    Args:
        value: The value to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range (must be > 0).
        out_max: The maximum of the output range (must be > 0).
        
    Returns:
        The exponentially mapped value in the output range
    """
    # First scale to 0..1 range linearly, then apply exponential scaling
    if value < in_min:
        return out_min
    elif value > in_max:
        return out_max
    var normalized = (value - in_min) / (in_max - in_min)
    return out_min * pow(out_max / out_min, normalized)

fn clip(val: Float64, lo: Float64, hi: Float64) -> Float64:
    if val < lo:
        return lo
    elif val > hi:
        return hi
    else:
        return val

fn clip(mut lst: List[Float64], lo: Float64, hi: Float64) -> None:
    """Clips each element in the list to the specified range."""
    for i in range(len(lst)):
        if lst[i] < lo:
            lst[i] = lo
        elif lst[i] > hi:
            lst[i] = hi

fn wrap(value: Float64, min_val: Float64, max_val: Float64) -> Float64:
    """Wraps a value around a specified range.
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

fn wrap(value: Int, min_val: Int, max_val: Int) -> Int:
    """Wraps a value around a specified range.
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

fn quadratic_interpolation(y0: Float64, y1: Float64, y2: Float64, x: Float64) -> Float64:
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

fn cubic_interpolation(p0: Float64, p1: Float64, p2: Float64, p3: Float64, t: Float64) -> Float64:
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

fn lin_interp(p0: Float64, p1: Float64, t: Float64) -> Float64:
    """Performs linear interpolation between two points.
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

fn mix(mut output: List[Float64], *samples: Float64) -> None:
    for i in range(len(output)):
        if i < len(samples):
            output[i] += samples[i]  # Sum the samples

fn mix(input: List[List[Float64]]) -> List[Float64]:
    var output = List[Float64]()
    for _ in range(len(input[0])):
        output.append(0.0)  # Initialize output list with zeros
    for lst in input:
        for i in range(len(output)):
            if i < len(lst):
                output[i] += lst[i]
    return output

fn mul(mut output: List[Float64], factor: Float64):
    """Multiplies each element in the output list by a factor."""
    for i in range(len(output)):
        output[i] *= factor  # Multiply each sample by the factor

# fn mul(output: List[Float64], factor: Float64) -> List[Float64]:
#     """Returns a new list with each element multiplied by the factor."""
#     var result = List[Float64](len(output), 0.0)
#     for i in range(len(output)):
#         result[i] = output[i] * factor  # Multiply each sample by the factor
#     return result

fn mul(left: List[Float64], right: List[Float64]) -> List[Float64]:
    """Returns a new list with each element multiplied by the corresponding factor."""

    var max_len = max(len(left), len(right))
    var result = List[Float64](max_len, 0.0)
    for i in range(max_len):
        result[i % max_len] = left[i % len(left)] * right[i % len(right)]  # Multiply each sample by the corresponding factor
    return result

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

fn zero(mut lst: List[Float64]) -> None:
    """Sets all elements of the list to zero."""
    for i in range(len(lst)):
        lst[i] = 0.0  # Set each element to zero

fn zapgremlins(x: Float64) -> Float64:
        var absx = abs(x)
        # Avoid NaN or Inf values
        return x if (absx > 1e-15 and absx < 1e15) else 0.0

from time import time

fn postln[*Ts: Writable](
    *values: *Ts
) -> None:
    """Prints elements to the text stream, each followed by a newline.
    Args:
        values: The elements to print.
    """
    if random_float64() < 0.01:  # Print timestamp with a 1% chance
        @parameter
        for i in range(values.__len__()):
            print(values[i], end=" ")
        print("", end="\n")

fn random_exp_float64(min: Float64, max: Float64) -> Float64:
    """Generates a random float64 value from an exponential distribution.
    Args:
        min: The minimum value (inclusive).
        max: The maximum value (inclusive).
    Returns:
        A random float64 value from the specified range.
    """
    var u = random_float64()
    return linexp(u, 0.0, 1.0, min, max)
