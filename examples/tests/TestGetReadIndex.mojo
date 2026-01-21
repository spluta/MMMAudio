from sys import simd_width_of

comptime simd_width = simd_width_of[DType.float64]()*2

fn main():

    # context
    delay_time = SIMD[DType.float64, simd_width](0.5289374923)
    samplerate: Int64 = 44100
    max_delay_seconds: Float64 = 2.0
    max_delay_samples: SIMD[DType.int64, simd_width] = SIMD[DType.int64, simd_width](max_delay_seconds * SIMD[DType.float64, simd_width](samplerate))
    # write_idx: Int64 = 1000
    write_idx: Int64 = 44101

    # stay in float land for the calculations
    float_sample_delay: SIMD[DType.float64, simd_width] = delay_time * SIMD[DType.float64, simd_width](samplerate)
    # modulus in float land
    float_read_idx: SIMD[DType.float64, simd_width] = SIMD[DType.float64, simd_width]((SIMD[DType.float64, simd_width](write_idx) - float_sample_delay) % SIMD[DType.float64, simd_width](max_delay_samples)) 
    int_read_idx: SIMD[DType.int64, simd_width] = SIMD[DType.int64, simd_width](float_read_idx)
    frac: SIMD[DType.float64, simd_width] = float_read_idx - SIMD[DType.float64, simd_width](int_read_idx)
    print("***** stay in float land *****")
    print("Float Sample Delay: ", float_sample_delay)
    print("Float Read Index: ", float_read_idx)
    print("Integer Read Index: ", int_read_idx)
    print("Fractional Part: ", frac)

    # int land
    float_sample_delay: SIMD[DType.float64, simd_width] = delay_time * SIMD[DType.float64, simd_width](samplerate)
    # convert to int right away?
    int_sample_delay: SIMD[DType.int64, simd_width] = SIMD[DType.int64, simd_width](float_sample_delay)
    # modulus in int land
    int_read_idx: SIMD[DType.int64, simd_width] = SIMD[DType.int64, simd_width]((write_idx - int_sample_delay) % max_delay_samples)
    frac: SIMD[DType.float64, simd_width] = float_sample_delay - SIMD[DType.float64, simd_width](int_sample_delay)
    print("***** int land *****")
    print("Float Sample Delay: ", float_sample_delay)
    print("Integer Sample Delay: ", int_sample_delay)
    print("Integer Read Index: ", int_read_idx)
    print("Fractional Part: ", frac)

    """
    staying in float land is more accurate. if one moves to ints 
    before subtracting the delay time from the write head, 
    it will truncate the wrong direction:

    max delay = 10
    float delay time = 1.1
    write head = 7

    truncate: 
    int delay time = 1
    read_head = write head - delay time = 6
    read_head = 6
    frac = float delay time - int delay time = 0.1

    so the "float read position" ends up being 6.1 but...

    write head (7) - float delay time (1.1) = should be 5.9 ???

    gotta stay in float land before write head - delay time:

    float read head = write head (7) - float delay time (1.1) = 5.9
    int read head = int(float read head) = 5
    frac = float read head - int read head = 0.9
    """
