from mmm_audio import *
from std.testing import assert_equal, assert_almost_equal, assert_true
from std.testing import TestSuite
from std.math import inf, nan
from std.pathlib import Path

# this should be more algorithmic

def test_cpsmidi_midicps() raises:
    midi_notes = MFloat[4](60.0, 69.0, 72.0, 81.0)
    frequencies = midicps(midi_notes)
    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python.functions")
    py_answer = List[Float64]()
    for i in range(len(midi_notes)):
        py_answer.append(py_to_float64(mmm_python.midicps(midi_notes[i])))
        assert_almost_equal(frequencies[i], py_answer[i], "Test: midicps mismatch at index " + String(i))
    recovered_midi = cpsmidi(frequencies)
    assert_almost_equal(midi_notes,recovered_midi,"Test: cpsmidi and midicps inversion failed")
    py_answer = List[Float64]()
    for i in range(len(py_answer)):
        py_answer.append(py_to_float64(mmm_python.cpsmidi(py_answer[i])))
        assert_almost_equal(midi_notes[i], py_answer[i], "Test: cpsmidi and midicps inversion failed")


def test_linlin() raises:
    x = MFloat[4](0.0, 0.5, 1.0, 1.5)
    result = linlin(x, 0.0, 1.0, -1.0, 1.0)
    expected = MFloat[4](-1.0, 0.0, 1.0, 1.0)
    assert_almost_equal(result, expected, "Test: linlin function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.linlin(x[i], 0.0, 1.0, -1.0, 1.0)))
        assert_almost_equal(result[i], py_answer[i], "Test: linlin mismatch at index " + String(i))

def test_linlin2() raises:
    x = MFloat[4](0.0, 0.5, 1.0, 1.5)
    result = linlin(x, 0.0, 1.0, 1.0, -1.0)
    expected = MFloat[4](1.0, 0.0, -1.0, -1.0)
    assert_almost_equal(result, expected, "Test: linlin function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.linlin(x[i], 0.0, 1.0, 1.0, -1.0)))
        assert_almost_equal(result[i], py_answer[i], "Test: linlin mismatch at index " + String(i))


def test_linexp() raises:
    x = MFloat[4](0.0, 0.5, 1.0, 1.5)
    result = linexp(x, 0.0, 1.0, 1.0, 10.0)
    expected = MFloat[4](1.0, 3.1622776601683795, 10.0, 10.0)
    assert_almost_equal(result, expected, "Test: linexp function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.linexp(x[i], 0.0, 1.0, 1.0, 10.0)))
        assert_almost_equal(result[i], py_answer[i], "Test: linexp mismatch at index " + String(i))

def test_linexp2() raises:
    x = MFloat[4](2.0, 3.1622776601683795, 10.0, 15.0)
    result = linexp(x, 1.0, 10.0, 10.0, 0.001)
    expected = MFloat[4](3.5938136638046, 1.093925400505, 0.001, 0.001)

    assert_almost_equal(result, expected, "Test: linexp function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.linexp(x[i], 1.0, 10.0, 10.0, 0.001)))
        assert_almost_equal(expected[i], py_answer[i], "Test: linexp mismatch at index " + String(i))
    result = linexp(x, 10.0, 1.0, 10.0, 0.001)
    assert_almost_equal(result, expected, "Test: linexp function failed")

    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.linexp(x[i], 1.0, 10.0, 10.0, 0.001)))
        assert_almost_equal(result[i], py_answer[i], "Test: linexp mismatch at index " + String(i))


def test_lincurve() raises:
    x = MFloat[4](0.234, 0.5, 1.0, 1.5)
    curve = [2.0, -2.0, 3.5, 0.5]
    expected = [
        MFloat[4](1.8406839040093, 3.42047279233, 10, 10),
        MFloat[4](4.89019954425, 7.57952720767, 10, 10),
        MFloat[4](1.3554075548362, 2.3324247822852, 10, 10), 
        MFloat[4](2.7219642975622, 4.9404114920278, 10, 10)
    ]
    for i in range(len(curve)):
        result = lincurve(x, 0.0, 1.0, 1.0, 10.0, curve[i])
        
        assert_almost_equal(result, expected[i], "Test: lincurve function failed")

        var cwd = Path()
        Python.add_to_path(cwd.path)
        mmm_python = Python.import_module("mmm_python")
        py_answer = SIMD[DType.float64, 4]()
        for i2 in range(len(x)):
            py_answer[i2]=(py_to_float64(mmm_python.lincurve(x[i2], 0.0, 1.0, 1.0, 10.0, curve[i])))
        assert_almost_equal(result, py_answer, "Test: lincurve mismatch at index " + String(i))

def test_lincurve2() raises:
    x = MFloat[4](0.234, 0.5, 1.0, 1.5)
    curve = [2.0, -2.0, 3.5, 0.5]
    expected = [
        MFloat[4](9.1593160959907, 7.57952720767, 1.0, 1.0),
        MFloat[4](6.10980045575, 3.42047279233, 1.0, 1.0),
        MFloat[4](9.6445924451638, 8.6675752177148, 1.0, 1.0), 
        MFloat[4](8.2780357024378, 6.0595885079722, 1.0, 1.0)
    ]
    for i in range(len(curve)):
        result = lincurve(x, 0.0, 1.0, 10.0, 1.0, curve[i])
        
        # assert_almost_equal(result, expected[i], "Test: lincurve function failed")

        var cwd = Path()
        Python.add_to_path(cwd.path)
        mmm_python = Python.import_module("mmm_python")
        py_answer = SIMD[DType.float64, 4]()
        for i2 in range(len(x)):
            py_answer[i2]=(py_to_float64(mmm_python.lincurve(x[i2], 0.0, 1.0, 10.0, 1.0, curve[i])))
        assert_almost_equal(result, py_answer, "Test: lincurve mismatch at index " + String(i))



def test_curvelin() raises:
    x = MFloat[4](0.234, 0.5, 1.0, 1.5)
    curve = [2.0, -2.0, 3.5, 0.5]
    expected = [
        MFloat[4](5.1143698508719, 7.4520137371736, 10, 10),
        MFloat[4](2.0172800628429, 3.5479862628264, 10, 10),
        MFloat[4](6.5075658522624, 8.2941226112612, 10, 10),
        MFloat[4](3.5438789977301, 6.0567364651629, 10, 10)
    ]
    for i in range(len(curve)):
        result = curvelin(x, 0.0, 1.0, 1.0, 10.0, curve[i])
        assert_almost_equal(result, expected[i], "Test: curvelin function failed")

        var cwd = Path()
        Python.add_to_path(cwd.path)
        mmm_python = Python.import_module("mmm_python")
        py_answer = SIMD[DType.float64, 4]()
        for i2 in range(len(x)):
            py_answer[i2]=(py_to_float64(mmm_python.curvelin(x[i2], 0.0, 1.0, 1.0, 10.0, curve[i])))
        assert_almost_equal(result, py_answer, "Test: curvelin mismatch at index " + String(i)) 

def test_curvelin2() raises:
    x = MFloat[4](0.234, 0.5, 1.0, 1.5)
    curve = [2.0, -2.0, 3.5, 0.5]
    expected = [
        MFloat[4](5.8856301491281, 3.5479862628264, 1.0, 1.0),
        MFloat[4](8.9827199371571, 7.4520137371736, 1.0, 1.0),
        MFloat[4](4.4924341477376, 2.7058773887388, 1.0, 1.0),
        MFloat[4](7.4561210022699, 4.9432635348371, 1.0, 1.0)
    ]

    for i in range(len(curve)):
        result = curvelin(x, 0.0, 1.0, 10.0, 1.0, curve[i])
        assert_almost_equal(result, expected[i], "Test: curvelin function failed")

        var cwd = Path()
        Python.add_to_path(cwd.path)
        mmm_python = Python.import_module("mmm_python")
        py_answer = SIMD[DType.float64, 4]()
        for i2 in range(len(x)):
            py_answer[i2]=(py_to_float64(mmm_python.curvelin(x[i2], 0.0, 1.0, 10.0, 1.0, curve[i])))
            assert_almost_equal(expected[i][i2], py_answer[i2], "Test: curvelin mismatch at index " + String(i)) 

def test_explin() raises:
    x = MFloat[4](1.0, 3.1622776601683795, 10.0, 15.0)
    result = explin(x, 1.0, 10.0, 0.0, 1.0)
    expected = MFloat[4](0.0, 0.5, 1.0, 1.0)
    assert_almost_equal(result, expected, "Test: explin function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.explin(x[i], 1.0, 10.0, 0.0, 1.0)))
        assert_almost_equal(result[i], py_answer[i], "Test: explin mismatch at index " + String(i))

def test_explin2() raises:
    x = MFloat[4](0.234, 0.5, 1.0, 1.5)
    expected = MFloat[4](2.8923524277696, 1.9030899869919, 1.0, 1.0)

    result = explin(x, 0.001, 1.0, 10.0, 1.0)
    assert_almost_equal(result, expected, "Test: explin function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = SIMD[DType.float64, 4]()
    for i2 in range(len(x)):
        py_answer[i2]=(py_to_float64(mmm_python.explin(x[i2], 0.001, 1.0, 10.0, 1.0)))
    assert_almost_equal(expected, py_answer, "Test: explin mismatch at index ") 

def test_expexp() raises:
    x = MFloat[4](1.0, 3.1622776601683795, 10.0, 15.0)
    result = expexp(x, 1.0, 10.0, 1.0, 10.0)
    expected = MFloat[4](1.0, 3.1622776601683795, 10.0, 10.0)
    assert_almost_equal(result, expected, "Test: expexp function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.expexp(x[i], 1.0, 10.0, 1.0, 10.0)))
        assert_almost_equal(result[i], py_answer[i], "Test: expexp mismatch at index " + String(i))

def test_expexp2() raises:
    x = MFloat[4](2.0, 3.1622776601683795, 10.0, 15.0)
    result = expexp(x, 1.0, 10.0, 10.0, 0.001)
    expected = MFloat[4](0.625, 0.1, 0.001, 0.001)
    assert_almost_equal(result, expected, "Test: expexp function failed")

    var cwd = Path()
    Python.add_to_path(cwd.path)
    mmm_python = Python.import_module("mmm_python")
    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.expexp(x[i], 1.0, 10.0, 10.0, 0.001)))
        assert_almost_equal(result[i], py_answer[i], "Test: expexp mismatch at index " + String(i))
    result = expexp(x, 10.0, 1.0, 10.0, 0.001)
    expected = MFloat[4](0.625, 0.1, 0.001, 0.001)
    assert_almost_equal(result, expected, "Test: expexp function failed")

    py_answer = List[Float64]()
    for i in range(len(x)):
        py_answer.append(py_to_float64(mmm_python.expexp(x[i], 1.0, 10.0, 10.0, 0.001)))
        assert_almost_equal(result[i], py_answer[i], "Test: expexp mismatch at index " + String(i))

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
    # test_mel_bands()