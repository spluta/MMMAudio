from mmm_audio import *
from testing import assert_equal, assert_almost_equal
# from testing import TestSuite
from math import inf, nan

def test_cpsmidi_midicps():
    midi_notes = SIMD[DType.float64, 4](60.0, 69.0, 72.0, 81.0)
    frequencies = midicps(midi_notes)
    recovered_midi = cpsmidi(frequencies)
    assert_almost_equal(midi_notes,recovered_midi,"Test: cpsmidi and midicps inversion failed")

def test_linear_interp():
    a = SIMD[DType.float64, 4](0.0, 10.0, 20.0, 30.0)
    b = SIMD[DType.float64, 4](10.0, 20.0, 30.0, 40.0)
    t = SIMD[DType.float64, 4](0.0, 0.5, 1.0, 0.25)
    result = linear_interp(a, b, t)
    expected = SIMD[DType.float64, 4](0.0, 15.0, 30.0, 32.5)
    assert_almost_equal(result, expected, "Test: lerp function failed")

def test_sanitize():
    nan = nan[DType.float64]()
    pos_inf = inf[DType.float64]()
    neg_inf = -inf[DType.float64]()
    values = SIMD[DType.float64, 4](1.0, nan, pos_inf, neg_inf)
    sanitized = sanitize(values)
    expected = SIMD[DType.float64, 4](1.0, 0.0, 0.0, 0.0)
    assert_almost_equal(sanitized, expected, "Test: sanitize function failed: ")

def main():
    # TestSuite.discover_tests[__functions_in_module()]().run()
    test_cpsmidi_midicps()
    test_linear_interp()
    test_sanitize()