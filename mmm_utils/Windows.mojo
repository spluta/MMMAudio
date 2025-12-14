from math import pi, exp, sin, sqrt, cos
from memory import memset_zero
from python import Python

struct WindowTypes:
    alias hann: Int = 0
    alias hamming: Int = 1
    alias blackman: Int = 2
    alias kaiser: Int = 3
    alias sine: Int = 4

fn bessel_i0(x: Float64) -> Float64:
    """
    Calculate the modified Bessel function of the first kind, order 0 (I₀).
    Uses polynomial approximation for accurate results.
    
    Args:
        x: Input value
        
    Returns:
        I₀(x)
    """
    var abs_x = abs(x)
    
    if abs_x < 3.75:
        # For |x| < 3.75, use polynomial approximation
        var t = (x / 3.75) ** 2
        return 1.0 + 3.5156229 * t + 3.0899424 * (t ** 2) + 1.2067492 * (t ** 3) + \
               0.2659732 * (t ** 4) + 0.0360768 * (t ** 5) + 0.0045813 * (t ** 6)
    else:
        # For |x| >= 3.75, use asymptotic expansion
        var t = 3.75 / abs_x
        var result = (exp(abs_x) / (abs_x ** 0.5)) * \
                    (0.39894228 + 0.01328592 * t + 0.00225319 * (t ** 2) - \
                     0.00157565 * (t ** 3) + 0.00916281 * (t ** 4) - \
                     0.02057706 * (t ** 5) + 0.02635537 * (t ** 6) - \
                     0.01647633 * (t ** 7) + 0.00392377 * (t ** 8))
        return result

fn kaiser_window(size: Int64, beta: Float64) -> List[Float64]:
    """
    Create a Kaiser window of length n with shape parameter beta.
    
    Args:
        n: Length of the window
        beta: Shape parameter that controls the trade-off between main lobe width and side lobe level
              - beta = 0: rectangular window
              - beta = 5: similar to Hamming window
              - beta = 6: similar to Hanning window
              - beta = 8.6: similar to Blackman window
    
    Returns:
        DynamicVector[Float64] containing the Kaiser window coefficients
    """
    var window = List[Float64]()  # Initialize window with zeros

    if size == 1:
        window.append(1.0)
        return window.copy()
    
    # Calculate the normalization factor
    var i0_beta = bessel_i0(beta)
    
    # Generate window coefficients
    for i in range(size):
        # Calculate the argument for the Bessel function
        var alpha = (Float64(size) - 1.0) / 2.0
        var arg = beta * sqrt(1.0 - ((Float64(i) - alpha) / alpha) ** 2)

        # Calculate Kaiser window coefficient
        var coeff = bessel_i0(arg) / i0_beta
        window.append(coeff)

    return window.copy()

fn build_sinc_table(size: Int64, ripples: Int64 = 4) -> List[Float64]:
    """
    Build a sinc function lookup table.
    
    Args:
        size: Number of points in the table
        ripples: Number of ripples/lobes on each side of the main lobe

    Returns:
        List containing the sinc function values
    """
    
    # Create evenly spaced points - the width is determined by ripples
    var width = Float64(ripples)
    # Create evenly spaced x values from -width*π to width*π
    var x_values = List[Float64]()

    var x_min = -width * 3.141592653589793
    var x_max = width * 3.141592653589793
    var step = (x_max - x_min) / Float64(size - 1)
    
    for i in range(size):
        x_values.append(x_min + step * Float64(i))

    # Calculate sinc values (handling the special case at x=0)
    var sinc_table = List[Float64]()

    for i in range(len(x_values)):
        if x_values[i] == 0:
            sinc_table.append(1.0)
        else:
            sinc_table.append(sin(x_values[i]) / x_values[i])

    # Apply Kaiser window to the sinc table
    # The beta parameter controls the trade-off between main lobe width and side lobe height
    beta = 5.0  # Typical values range from 5 to 8 for audio processing

    window = kaiser_window(size, beta)
    for i in range(len(sinc_table)):
        sinc_table[i] *= window[i]  # Apply the window to the sinc values
    
    return sinc_table.copy()

fn hann_window(n: Int64) -> List[Float64]:
    """
    Generate a Hann window of length n.
    
    Args:
        n: Length of the window
        
    Returns:
        List containing the Hann window values
    """
    var window = List[Float64]()
    
    for i in range(n):
        var value = 0.5 * (1.0 - cos(2.0 * pi * Float64(i) / Float64(n - 1)))
        window.append(value)
    
    return window.copy()

fn hamming_window(n: Int64) -> List[Float64]:
    """
    Generate a Hamming window of length n.
    """
    var window = List[Float64]()
    for i in range(n):
        var value = 0.54 - 0.46 * cos(2.0 * pi * Float64(i) / Float64(n - 1))
        window.append(value)

    return window.copy()

fn blackman_window(n: Int64) -> List[Float64]:
    """Generate a Blackman window of length n.
    Args:
        n: Length of the window
    Returns:
        List containing the Blackman window values
    """
    var window = List[Float64]()
    for i in range(n):
        var value = 0.42 - 0.5 * cos(2.0 * pi * Float64(i) / Float64(n - 1)) + \
                    0.08 * cos(4.0 * pi * Float64(i) / Float64(n - 1))
        window.append(value)
    return window.copy()

fn sine_window(n: Int64) -> List[Float64]:
    """
    Generate a Sine window of length n.
    Args:
        n: Length of the window
    Returns:
        List containing the Sine window values
    """
    var window = List[Float64]()
    for i in range(n):
        var value = sin(pi * Float64(i) / Float64(n - 1))
        window.append(value)
    return window.copy()

# Create a compile-time function to generate values
fn pan_window(size: Int64) -> List[SIMD[DType.float64, 2]]:
    """
    Generate a SIMD[DType.float64, 2] quarter cosine window for panning. value 0 is for the left channel, value 1 is for the right channel.
    0 = cos(0) = 1.0 (full left)
    1 = cos(pi/2) = 0.0 (no left)
    
    Args:
        size: Length of the window
    Returns:
        List containing the quarter cosine window values
    """
    var table = List[SIMD[DType.float64, 2]]()

    for i in range(size):
        var angle = (pi / 2.0) * Float64(i) / Float64(size-1)
        table.append(cos(SIMD[DType.float64, 2](angle, (pi / 2.0) - angle)))
    return table^
