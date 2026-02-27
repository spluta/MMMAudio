from mmm_audio import *
from testing import assert_equal, assert_almost_equal, assert_true
from testing import TestSuite
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

def test_mel_to_hz():
    """Compare mel_to_hz against librosa's implementation."""
    librosa_results = SIMD[DType.float64, 8](345123.07093968056, 334060977.5717811, 323353453109.8285, 312989132696839.3, 3.029570157490985e+17, 2.932464542802523e+20, 2.8384714159964454e+23, 2.747491013729005e+26)
    mels = SIMD[DType.float64, 8](100.0, 200.0, 300.0, 400.0, 500.0, 600.0, 700.0, 800.0)
    mmm_results = SIMD[DType.float64, 8]()
    for i in range(8):
        mmm_results[i] = MelBands.mel_to_hz(mels[i])
    assert_almost_equal(mmm_results, librosa_results, "Test: mel_to_hz function failed")

def test_hz_to_mel():
    """Compare hz_to_mel against librosa's implementation."""
    librosa_results = SIMD[DType.float64, 8](100.0, 200.0, 300.0, 400.0, 500.0, 600.0, 700.0, 800.0)
    hz_values = SIMD[DType.float64, 8](345123.07093968056, 334060977.5717811, 323353453109.8285, 312989132696839.3, 3.029570157490985e+17, 2.932464542802523e+20, 2.8384714159964454e+23, 2.747491013729005e+26)
    mmm_results = SIMD[DType.float64, 8]()
    for i in range(8):
        mmm_results[i] = MelBands.hz_to_mel(hz_values[i])
    assert_almost_equal(mmm_results, librosa_results, "Test: hz_to_mel function failed")

def test_diff():
    arr = List[Float64]([1.0, 2.5, 4.0, 7.0, 10.0])
    expected = List[Float64]([1.5, 1.5, 3.0, 3.0])
    result = diff(arr)

    result_simd = SIMD[DType.float64, 4](result[0], result[1], result[2], result[3])
    expected_simd = SIMD[DType.float64, 4](expected[0], expected[1], expected[2], expected[3])
    assert_almost_equal(result_simd, expected_simd, "Test: diff function failed")

def test_linspace():
    start = 0.0
    stop = 1.0
    num = 8
    result = linspace(start, stop, num)
    result_simd = SIMD[DType.float64, 8](result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7])
    expected = SIMD[DType.float64, 8](0.0, 0.14285714285714285, 0.2857142857142857, 0.42857142857142855, 0.5714285714285714, 0.7142857142857143, 0.8571428571428571, 1.0)
    assert_almost_equal(result_simd, expected, "Test: linspace function failed")

def test_mel_frequencies():
    num_mel_bins = 32
    fmin = 20.0
    fmax = 20000.0
    result = MelBands.mel_frequencies(num_mel_bins, fmin, fmax)
    result_simd = SIMD[DType.float64, 32]()
    for i in range(32):
        result_simd[i] = result[i]
    expected = SIMD[DType.float64, 32](20.0, 145.31862602399627, 270.63725204799255, 395.95587807198876, 521.274504095985, 646.5931301199813, 771.9117561439776, 897.2303821679739, 1023.526754399107, 1164.733656827089, 1325.421622361244, 1508.2782803824396, 1716.3620486443097, 1953.15328765427, 2222.6125123704865, 2529.2466348500357, 2878.184345807327, 3275.2618958971248, 3727.120711479871, 4241.318477567799, 4826.455545899264, 5492.318782413196, 6250.04526008295, 7112.308534997669, 8093.530621301341, 9210.123210432963, 10480.762169244366, 11926.699908187227, 13572.120844166513, 15444.545903449043, 17575.292830248403, 19999.999999999996)
    assert_almost_equal(result_simd, expected, "Test: mel_frequencies function failed")

def test_fft_frequencies():
    sample_rate = 44100.0
    n_fft = 512
    result = RealFFT.fft_frequencies(sample_rate, n_fft)
    result_simd = SIMD[DType.float64, 8]()
    for i in range(8):
        result_simd[i] = result[i]
    expected = SIMD[DType.float64, 8](0.0, 86.1328125, 172.265625, 258.3984375, 344.53125, 430.6640625, 516.796875, 602.9296875)
    assert_almost_equal(result_simd, expected, "Test: fft_frequencies function failed")

def test_dct():
    dct = DCT[4,3]()
    input_vals = List[Float64]([1.0, 2.0, 3.0, 4.0])
    output_vals = List[Float64](length=3, fill=0.0)
    dct.process(input_vals, output_vals)

    expected = List[Float64]([5.0, -2.230442497387663, -6.280369834735101e-16])
    for i in range(len(output_vals)):
        assert_almost_equal(output_vals[i], expected[i], "Test: DCT coefficient mismatch")

def test_mfcc_paths_consistency():
    """Ensure MFCC outputs match across next_frame, from_mags, and from_mel_bands."""
    comptime fft_size: Int = 64
    comptime num_bands: Int = 8
    comptime num_coeffs: Int = 4

    w = alloc[MMMWorld](1) 
    w.init_pointee_move(MMMWorld(48000.0))

    mags = List[Float64](length=(fft_size // 2) + 1, fill=0.0)
    phases = List[Float64](length=(fft_size // 2) + 1, fill=0.0)

    for i in range(len(mags)):
        mags[i] = 0.001 + 0.001 * Float64(i)

    mel = MelBands[num_bands=num_bands,min_freq=20.0,max_freq=20000.0,fft_size=fft_size](w)
    mel.from_mags(mags)

    mfcc_next = MFCC[num_coeffs=num_coeffs,num_bands=num_bands,min_freq=20.0,max_freq=20000.0,fft_size=fft_size](w)
    mfcc_mags = MFCC[num_coeffs=num_coeffs,num_bands=num_bands,min_freq=20.0,max_freq=20000.0,fft_size=fft_size](w)
    mfcc_bands = MFCC[num_coeffs=num_coeffs,num_bands=num_bands,min_freq=20.0,max_freq=20000.0,fft_size=fft_size](w)

    mfcc_next.next_frame(mags, phases)
    mfcc_mags.from_mags(mags)
    mfcc_bands.from_mel_bands(mel.bands)

    for i in range(num_coeffs):
        assert_almost_equal(mfcc_next.coeffs[i], mfcc_mags.coeffs[i], "Test: MFCC next_frame vs from_mags mismatch")
        assert_almost_equal(mfcc_next.coeffs[i], mfcc_bands.coeffs[i], "Test: MFCC next_frame vs from_mel_bands mismatch")

def _test_mel_bands_weights[n_mels: Int, n_fft: Int, sr: Int]():
    w = alloc[MMMWorld](1) 
    w.init_pointee_move(MMMWorld(sample_rate = sr))
    melbands = MelBands[num_bands=n_mels,min_freq=20.0,max_freq=20000.0,fft_size=n_fft](w)

    print("=======================================")
    print("Testing mel bands with parameters:")
    print("n_mels: ", n_mels)
    print("n_fft: ", n_fft)
    print("sr: ", sr)

    # print("melbands weights shape: ")
    # print(len(melbands.weights))
    # print(len(melbands.weights[0]))

    weights_flat = List[Float64]()

    for i in range(len(melbands.weights)):
        for j in range(len(melbands.weights[i])):
            weights_flat.append(Float64(melbands.weights[i][j]))

    # print("melband weights flat len: ", len(weights_flat))

    expected_path = "testing_mmm_audio/validation/librosa_results/librosa_mel_bands_weights_results"
    expected_path += "_nmels=" + String(n_mels)
    expected_path += "_fftsize=" + String(n_fft)
    expected_path += "_sr=" + String(sr)
    expected_path += ".csv"

    # print("loading: ",expected_path)

    expected_flat = List[Float64]()

    with open(expected_path, "r") as f:
        string = f.read()
        lines = string.split("\n")
        for line in lines:
            l = line.strip()
            if len(l) > 0:
                expected_flat.append(Float64(l))

    compare_long_lists(weights_flat, expected_flat)

def compare_long_lists[chunk_size: Int = 64](a: List[Float64], b: List[Float64], verbose: Bool = False):
    assert_equal(len(a), len(b), "Lists are of different lengths")
    a_simd = SIMD[DType.float64,chunk_size]()
    b_simd = SIMD[DType.float64,chunk_size]()

    i: Int = 0
    while i < len(a):
        a_simd[i % chunk_size] = a[i]
        b_simd[i % chunk_size] = b[i]
        if i > 0 and i % chunk_size == 0:
            if verbose:
                print("Comparing chunk ending at index ", i)
            assert_almost_equal(a_simd,b_simd)
        i += 1

def test_all_mel_bands_weights():
    _test_mel_bands_weights[40,512,44100]()

def main():
    TestSuite.discover_tests[__functions_in_module()]().run()
    # test_mel_bands()