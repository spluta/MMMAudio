from math import log, log1p, pi


from math import exp, log, log1p, cosh, pi


fn horner[num_chans: Int](z: SIMD[DType.float64, num_chans], coeffs: List[Float64]) -> SIMD[DType.float64, num_chans]:
    """Evaluate polynomial using Horner's method."""
    var result: SIMD[DType.float64, num_chans] = 0.0
    for i in range(len(coeffs) - 1, -1, -1):
        result = result * z + coeffs[i]
    return result


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

    alias pi_sq = pi * pi

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


# fn main():
#     # Test the Li2 function
#     print("Li2(0.0) =", Li2(0.0))
#     print("Li2(0.5) =", Li2(0.5))
#     print("Li2(1.0) =", Li2(1.0))
#     print("Li2(-1.0) =", Li2(-1.0))
#     print("Li2(2.0) =", Li2(2.0))