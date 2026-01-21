from random import random_float64
from math import *

struct Changed(Representable, Movable, Copyable):
    """Detect changes in a Bool value."""
    var last_val: Bool  # Store the last value

    fn __init__(out self, initial: Bool = False):
        """Initialize the Changed struct.

        Args:
            initial: The initial value to compare against.
        """
        self.last_val = initial  # Initialize last value

    fn __repr__(self) -> String:
        return String("Changed")

    fn next(mut self, val: Bool) -> Bool:
        """Check if the value has changed.
        
        Args:
            val: The current value to check.
        
        Returns:
            True if the value has changed since the last check, False otherwise.
        """
        if val != self.last_val:
            self.last_val = val  # Update last value
            return True
        return False

@always_inline
fn dbamp[width: Int, //](db: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    """Converts decibel values to amplitude.

    amplitude = 10^(dB/20).

    Parameters:
        width: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        db: The decibel values to convert.

    Returns:
        The corresponding amplitude values.
    """
    return 10.0 ** (db / 20.0)

@always_inline
fn ampdb[width: Int, //](amp: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]:
    """Converts amplitude values to decibels.

    dB = 20 * log10(amplitude).

    Parameters:
        width: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        amp: The amplitude values to convert.

    Returns:
        The corresponding decibel values.
    """
    return 20.0 * log10(amp)

@always_inline
fn select[num_chans: Int, //](index: Float64, vals: SIMD[DType.float64, num_chans]) -> Float64:
    """Selects a value from a SIMD vector based on a floating-point index and using linear interpolation.

    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        index: The floating-point index to select.
        vals: The SIMD vector containing the values.
    
    Returns:
        The selected value.
    """
    index_int = Int(index) % len(vals)
    index_mix: Float64 = index - index_int
    v0 = vals[index_int]
    v1 = vals[(index_int + 1) % len(vals)]
    return linear_interp(v0, v1, index_mix)

@always_inline
fn select[num_chans: Int](index: Float64, vals: List[SIMD[DType.float64, num_chans]]) -> SIMD[DType.float64, num_chans]:
    """Selects a SIMD vector from a List of SIMD vectors based on a floating-point index using linear interpolation.

    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        index: The floating-point index to select.
        vals: The List of SIMD vectors containing the values.
    
    Returns:
        The selected value.
    """
    index_int = Int(index) % len(vals)
    index_mix: Float64 = index - index_int
    v0 = vals[index_int]
    v1 = vals[(index_int + 1) % len(vals)]
    return linear_interp(v0, v1, index_mix)

@always_inline
fn linlin[
    dtype: DType, num_chans: Int, //
](input: SIMD[dtype, num_chans], in_min: SIMD[dtype, num_chans] = 0, in_max: SIMD[dtype, num_chans] = 1, out_min: SIMD[dtype, num_chans] = 0, out_max: SIMD[dtype, num_chans] = 1) -> SIMD[dtype, num_chans]:
    """Maps samples from one range to another range linearly.

    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Samples outside the input range are clamped to the corresponding output boundaries.

    Args:
        input: The samples to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range.
        out_max: The maximum of the output range.
    """
    output = input

    # Create masks for the conditions
    below_min: SIMD[DType.bool, num_chans] = output.lt(in_min)
    above_max: SIMD[DType.bool, num_chans] = output.gt(in_max)

    scaled = (input - in_min) / (in_max - in_min) * (out_max - out_min) + out_min

    # Use select to choose the right value based on conditions
    return below_min.select(out_min,
       above_max.select(out_max, scaled))

@always_inline
fn linexp[num_chans: Int, //
](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Maps samples from one linear range to another exponential range.

    Parameters:
        num_chans: Size of the SIMD vector - defaults to 1. This parameter is inferred by the values passed to the function.

    Args:
        input: The samples to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range (must be > 0).
        out_max: The maximum of the output range (must be > 0).

    Returns:
        The exponentially mapped samples in the output range.
    """
    below_min: SIMD[DType.bool, num_chans] = input.lt(in_min)
    above_max: SIMD[DType.bool, num_chans] = input.gt(in_max)
    normalized = (input - in_min) / (in_max - in_min)
    exponential_scaled = out_min * pow(out_max / out_min, normalized)

    return below_min.select(out_min,
        above_max.select(out_max, exponential_scaled))

@always_inline
fn lincurve[num_chans: Int, //
](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans], curve: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Maps samples from one linear range to another curved range.

    Parameters:
        num_chans: Size of the SIMD vector - defaults to 1. This parameter is inferred by the values passed to the function.

    Args:
        input: The samples to map.
        in_min: The minimum of the input range.
        in_max: The maximum of the input range.
        out_min: The minimum of the output range (must be > 0).
        out_max: The maximum of the output range (must be > 0).
        curve: The curve factor. Positive values create an exponential-like curve, negative values create a logarithmic-like curve, and zero results in a linear mapping.

    Returns:
        The curved mapped samples in the output range.
    """
    # Handle zero curve values to avoid NaN
    curve_zero: SIMD[DType.bool, num_chans] = curve == 0.0
    temp_curve: SIMD[DType.float64, num_chans] = curve_zero.select(0.0001, curve)

    # Create condition masks
    below_min: SIMD[DType.bool, num_chans] = input.lt(in_min)
    above_max: SIMD[DType.bool, num_chans] = input.gt(in_max)

    # Compute exponential curve parameters for all elements
    grow = pow(SIMD[DType.float64, num_chans](2.71828182845904523536), temp_curve)  # e^curve
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
    dtype: DType, num_chans: Int, //
](x: SIMD[dtype, num_chans], lo: SIMD[dtype, num_chans], hi: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]:
    """Clips each element in the SIMD vector to the specified range.

    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        x: The SIMD vector to clip. Each element will be clipped individually.
        lo: The minimum possible value.
        hi: The maximum possible value.

    Returns:
        The clipped SIMD vector.
    """ 
    return min(max(x, lo), hi)

@always_inline
fn wrap[
    dtype: DType, num_chans: Int, //
](input: SIMD[dtype, num_chans], min_val: SIMD[dtype, num_chans], max_val: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]:
    """Wraps a sample around a specified range.

    The wrapped sample within the range [min_val, max_val). 
    This function uses modulus arithmetic so the output can never equal max_val.
    Returns the sample if min_val >= max_val.

    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        input: The sample to wrap.
        min_val: The minimum of the range.
        max_val: The maximum of the range.

    Returns:
        The wrapped value.
    """
    # Check if any min_val >= max_val (vectorized comparison)
    var invalid_range: SIMD[DType.bool, num_chans] = min_val >= max_val
    
    var range_size = max_val - min_val
    var wrapped_sample = (input - min_val) % range_size + min_val
    
    # Handle negative modulo results (vectorized)
    var needs_adjustment: SIMD[DType.bool, num_chans] = wrapped_sample.lt(min_val)

    wrapped_sample = needs_adjustment.select(wrapped_sample + range_size, wrapped_sample)

    # Return original input where range is invalid, wrapped result otherwise
    return invalid_range.select(input, wrapped_sample)

@always_inline
fn quadratic_interp[
    dtype: DType, num_chans: Int, //
](y0: SIMD[dtype, num_chans], y1: SIMD[dtype, num_chans], y2: SIMD[dtype, num_chans], x: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]:
    """Performs quadratic interpolation between three points.

    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.
    
    Args:
        y0: The sample at position 0.
        y1: The sample at position 1.
        y2: The sample at position 2.
        x: The interpolation position (fractional part between 0 and 1).

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
    dtype: DType, num_chans: Int, //
](p0: SIMD[dtype, num_chans], p1: SIMD[dtype, num_chans], p2: SIMD[dtype, num_chans], p3: SIMD[dtype, num_chans], t: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]:
    """
    Performs cubic interpolation.

    Cubic Intepolation equation from *The Audio Programming Book* 
    by Richard Boulanger and Victor Lazzarini. pg. 400

    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.
    
    Args:
        p0: Point to the left of p1.
        p1: Point to the left of the float t.
        p2: Point to the right of the float t.
        p3: Point to the right of p2.
        t: Interpolation parameter (fractional part between p1 and p2).
    
    Returns:
        Interpolated sample.
    """
    return p1 + (((p3 - p0 - 3*p2 + 3*p1)*t + 3*(p2 + p0 - 2*p1))*t - (p3 + 2*p0 - 6*p2 + 3*p1))*t / 6.0

@always_inline
fn lagrange4[
    dtype: DType, num_chans: Int, //
](sample0: SIMD[dtype, num_chans], sample1: SIMD[dtype, num_chans], sample2: SIMD[dtype, num_chans], sample3: SIMD[dtype, num_chans], sample4: SIMD[dtype, num_chans], frac: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]:
    """
    Perform Lagrange interpolation for 4th order case (from JOS Faust Model). This is extrapolated from the JOS Faust filter model.

    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        sample0: The first sample.
        sample1: The second sample.
        sample2: The third sample.
        sample3: The fourth sample.
        sample4: The fifth sample.
        frac: The fractional part between sample0 and sample1.

    Returns:
        The interpolated sample.
    """

    comptime o = 1.4999999999999999  # to avoid edge case issues
    var fd = o + frac

    # simd optimized!
    var out: SIMD[dtype, num_chans] = SIMD[dtype, num_chans](0.0)

    var fdm1: SIMD[dtype, num_chans] = SIMD[dtype, num_chans](0.0)
    var fdm2: SIMD[dtype, num_chans] = SIMD[dtype, num_chans](0.0)
    var fdm3: SIMD[dtype, num_chans] = SIMD[dtype, num_chans](0.0)
    var fdm4: SIMD[dtype, num_chans] = SIMD[dtype, num_chans](0.0)

    comptime offsets = SIMD[dtype, 4](1.0, 2.0, 3.0, 4.0)

    @parameter
    for i in range(num_chans):
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

    @parameter
    for i in range(num_chans):
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
fn linear_interp[
    dtype: DType, num_chans: Int, //
](p0: SIMD[dtype, num_chans], p1: SIMD[dtype, num_chans], t: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]:
    """
    Performs linear interpolation between two points.
    
    Parameters:
        dtype: The data type of the SIMD vector. This parameter is inferred by the values passed to the function.
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        p0: The starting point.
        p1: The ending point.
        t: The interpolation parameter (fractional part between p0 and p1).
    
    Returns:
        The interpolated sample.
    """
    
    return p0 + ((p1 - p0) * t)

@always_inline
fn midicps[
    num_chans: Int, //
](midi_note_number: SIMD[DType.float64, num_chans], reference_midi_note: Float64 = 69, reference_frequency: Float64 = 440.0) -> SIMD[DType.float64, num_chans]:
    """Convert MIDI note numbers to frequencies in Hz.

    (cps = "cycles per second")

    Conversion happens based on equating the `reference_midi_note` to the `reference_frequency`.
    For standard tuning, leave the defaults of MIDI note 69 (A4) and 440.0 Hz.

    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        midi_note_number: The MIDI note number(s) to convert.
        reference_midi_note: The reference MIDI note number.
        reference_frequency: The frequency of the reference MIDI note.
    
    Returns:
        Frequency in Hz.
    """
    
    frequency = Float64(reference_frequency) * 2.0 ** ((midi_note_number - reference_midi_note) / 12.0)
    return frequency

@always_inline
fn cpsmidi[
    num_chans: Int, //
](freq: SIMD[DType.float64, num_chans], reference_midi_note: Float64 = 69.0, reference_frequency: Float64 = 440.0) -> SIMD[DType.float64, num_chans]:
    """Convert frequencies in Hz to MIDI note numbers.
    
    (cps = "cycles per second")

    Conversion happens based on equating the `reference_midi_note` to the `reference_frequency`.
    For standard tuning, leave the defaults of MIDI note 69 (A4) and 440.0 Hz.

    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        freq: The frequency in Hz to convert.
        reference_midi_note: The reference MIDI note number.
        reference_frequency: The frequency of the reference MIDI note.

    Returns:
        The corresponding MIDI note number.
    """

    n = 12.0 * log2(abs(freq) / reference_frequency) + reference_midi_note
    return n

@always_inline
fn sanitize[
    num_chans: Int, //
](mut x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Sanitizes a SIMD float64 vector by zeroing out elements that are too large, too small, or NaN.
    
    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        x: The SIMD float64 vector to sanitize.
    
    Returns:
        The sanitized SIMD float64 vector.
    """

    var absx = abs(x)
    too_large: SIMD[DType.bool, num_chans] = absx.gt(SIMD[DType.float64, num_chans](1e15))
    too_small: SIMD[DType.bool, num_chans] = absx.lt(SIMD[DType.float64, num_chans](1e-15))
    is_nan: SIMD[DType.bool, num_chans] = x.ne(x)
    should_zero: SIMD[DType.bool, num_chans] = too_large | too_small | is_nan

    return should_zero.select(0.0, x)

fn random_uni_float64[num_chans: Int = 1](min: SIMD[DType.float64, num_chans], max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Generates a random float64 sample from a uniform distribution.

    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        min: The minimum sample (inclusive).
        max: The maximum sample (inclusive).
    Returns:
        A random float64 sample from the specified range.
    """
    var u = SIMD[DType.float64, num_chans](0.0)
    @parameter
    for i in range(num_chans):
        u[i] = random_float64(min[i], max[i])
    return u

@always_inline
fn random_exp_float64[num_chans: Int, //](min: SIMD[DType.float64, num_chans], max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Generates a random float64 sample from an exponential distribution.

    Parameters:
        num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        min: The minimum sample (inclusive).
        max: The maximum sample (inclusive).
    Returns:
        A random float64 sample from the specified range.
    """
    var u = SIMD[DType.float64, num_chans](0.0)
    @parameter
    for i in range(num_chans):
        u[i] = random_float64()
    u = linexp(u, 0.0, 1.0, min, max)
    return u

@doc_private
fn horner[num_chans: Int](z: SIMD[DType.float64, num_chans], coeffs: List[Float64]) -> SIMD[DType.float64, num_chans]:
    """Evaluate polynomial using Horner's method."""
    var result: SIMD[DType.float64, num_chans] = 0.0
    for i in range(len(coeffs) - 1, -1, -1):
        result = result * z + coeffs[i]
    return result

@doc_private
fn Li2[num_chans: Int](x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Compute the dilogarithm (Spence's function) Li2(x) for SIMD vectors."""

    # Coefficients for double precision
    var P = List[Float64]()
    P.append(1.07061055633093042767673531395124630e+0)
    P.append(-5.25056559620492749887983310693176896e+0)
    P.append(1.03934845791141763662532570563508185e+1)
    P.append(-1.06275187429164237285280053453630651e+1)
    P.append(5.95754800847361224707276004888482457e+0)
    P.append(-1.78704147549824083632603474038547305e+0)
    P.append(2.56952343145676978700222949739349644e-1)
    P.append(-1.33237248124034497789318026957526440e-2)
    P.append(7.91217309833196694976662068263629735e-5)

    var Q = List[Float64]()
    Q.append(1.00000000000000000000000000000000000e+0)
    Q.append(-5.20360694854541370154051736496901638e+0)
    Q.append(1.10984640257222420881180161591516337e+1)
    Q.append(-1.24997590867514516374467903875677930e+1)
    Q.append(7.97919868560471967115958363930214958e+0)
    Q.append(-2.87732383715218390800075864637472768e+0)
    Q.append(5.49210416881086355164851972523370137e-1)
    Q.append(-4.73366369162599860878254400521224717e-2)
    Q.append(1.23136575793833628711851523557950417e-3)

    comptime pi_sq = pi * pi

    # Initialize output variables
    var y: SIMD[DType.float64, num_chans] = 0.0
    var r: SIMD[DType.float64, num_chans] = 0.0
    var s: SIMD[DType.float64, num_chans] = 1.0

    var mask1: SIMD[DType.bool, num_chans] = x.lt(-1.0)
    if mask1.reduce_or():
        var l1 = log(1.0 - x)
        var y1 = 1.0 / (1.0 - x)
        var r1 = -pi_sq / 6.0 + l1 * (0.5 * l1 - log(-x))
        y = mask1.select(y1, y)
        r = mask1.select(r1, r)
        s = mask1.select(SIMD[DType.float64, num_chans](1.0), s)

    # Case 2: x == -1
    var mask2: SIMD[DType.bool, num_chans] = x.eq(-1.0)
    if mask2.reduce_or():
        r = mask2.select(SIMD[DType.float64, num_chans](-pi_sq / 12.0), r)
        y = mask2.select(SIMD[DType.float64, num_chans](0.0), y)
        s = mask2.select(SIMD[DType.float64, num_chans](0.0), s)  # Will return r directly

    # Case 3: -1 < x < 0
    var mask3: SIMD[DType.bool, num_chans] = (x.gt(-1.0)) & (x.lt(0.0))
    if mask3.reduce_or():
        var l3 = log1p(-x)
        var y3 = x / (x - 1.0)
        var r3 = -0.5 * l3 * l3
        y = mask3.select(y3, y)
        r = mask3.select(r3, r)
        s = mask3.select(SIMD[DType.float64, num_chans](-1.0), s)

    # Case 4: x == 0
    var mask4: SIMD[DType.bool, num_chans] = x.eq(0.0)
    if mask4.reduce_or():
        r = mask4.select(SIMD[DType.float64, num_chans](0.0), r)
        y = mask4.select(SIMD[DType.float64, num_chans](0.0), y)
        s = mask4.select(SIMD[DType.float64, num_chans](0.0), s)

    # Case 5: 0 < x < 0.5
    var mask5: SIMD[DType.bool, num_chans] = (x.gt(0.0)) & (x.lt(0.5))
    if mask5.reduce_or():
        y = mask5.select(x, y)
        r = mask5.select(SIMD[DType.float64, num_chans](0.0), r)
        s = mask5.select(SIMD[DType.float64, num_chans](1.0), s)

    # Case 6: 0.5 <= x < 1
    var mask6: SIMD[DType.bool, num_chans] = (x.ge(0.5)) & (x.lt(1.0))
    if mask6.reduce_or():
        var y6 = 1.0 - x
        var r6 = pi_sq / 6.0 - log(x) * log(1.0 - x)
        y = mask6.select(y6, y)
        r = mask6.select(r6, r)
        s = mask6.select(SIMD[DType.float64, num_chans](-1.0), s)

    # Case 7: x == 1
    var mask7: SIMD[DType.bool, num_chans] = x.eq(1.0)
    if mask7.reduce_or():
        r = mask7.select(SIMD[DType.float64, num_chans](pi_sq / 6.0), r)
        y = mask7.select(SIMD[DType.float64, num_chans](0.0), y)
        s = mask7.select(SIMD[DType.float64, num_chans](0.0), s)

    # Case 8: 1 < x < 2
    var mask8: SIMD[DType.bool, num_chans] = (x.gt(1.0)) & (x.lt(2.0))
    if mask8.reduce_or():
        var l8 = log(x)
        var y8 = 1.0 - 1.0 / x
        var r8 = pi_sq / 6.0 - l8 * (log(1.0 - 1.0 / x) + 0.5 * l8)
        y = mask8.select(y8, y)
        r = mask8.select(r8, r)
        s = mask8.select(SIMD[DType.float64, num_chans](1.0), s)

    # Case 9: x >= 2
    var mask9: SIMD[DType.bool, num_chans] = x.ge(2.0)
    if mask9.reduce_or():
        var l9 = log(x)
        var y9 = 1.0 / x
        var r9 = pi_sq / 3.0 - 0.5 * l9 * l9
        y = mask9.select(y9, y)
        r = mask9.select(r9, r)
        s = mask9.select(SIMD[DType.float64, num_chans](-1.0), s)

    # Compute polynomial approximation
    var z = y - 0.25

    var p = horner[num_chans](z, P)
    var q = horner[num_chans](z, Q)

    return r + s * y * p / q

fn sign[num_chans:Int,//](x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
    """Returns the sign of x: -1 if negative, 1 if positive, and 0 if zero.
    
    Parameters:
        num_chans: Number of channels in the SIMD vector. This parameter is inferred by the values passed to the function.

    Args:
        x: The input SIMD vector.

    Returns:
        A SIMD vector containing the sign of each element in x.
    """
    pmask:SIMD[DType.bool, num_chans] = x.gt(0.0)
    nmask:SIMD[DType.bool, num_chans] = x.lt(0.0)

    return pmask.select(SIMD[DType.float64, num_chans](1.0), nmask.select(SIMD[DType.float64, num_chans](-1.0), SIMD[DType.float64, num_chans](0.0)))