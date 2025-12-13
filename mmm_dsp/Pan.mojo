from mmm_utils.functions import clip, linlin
from mmm_src.MMMWorld import *
from math import sqrt, floor, cos, pi, sin
from bit import next_power_of_two
from sys import simd_width_of
from mmm_utils.functions import *

@always_inline
fn pan2(samples: Float64, pan: Float64) -> SIMD[DType.float64, 2]:
    var pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    var gains = SIMD[DType.float64, 2](-pan2, pan2)

    samples_out = samples * sqrt((1 + gains) * 0.5)
    return samples_out  # Return stereo output as List

@always_inline
fn pan2_st(samples: SIMD[DType.float64, 2], pan: Float64) -> SIMD[DType.float64, 2]:
    var pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    var gains = SIMD[DType.float64, 2](-pan2, pan2)

    samples_out = samples * sqrt((1 + gains) * 0.5)
    return samples_out  # Return stereo output as List

alias pi_over_2 = pi / 2.0

@always_inline
fn splay(input: List[Float64], w: UnsafePointer[MMMWorld]) -> SIMD[DType.float64, 2]:

    num_input_channels = len(input)
    out = SIMD[DType.float64, 2](0.0)

    for i in range(num_input_channels):
        if num_input_channels == 1:
            out = input[0] * SIMD[DType.float64, 2](0.7071, 0.7071)
        else:
            pan = Float64(i) / Float64(num_input_channels - 1)

            out += input[i] * w[].pan_window[Int(pan * Float64(len(w[].pan_window) - 1))]
    return out

@always_inline
fn pan_az[simd_size: Int = 2](sample: Float64, pan: Float64, num_speakers: Int64, width: Float64 = 2.0, orientation: Float64 = 0.5) -> SIMD[DType.float64, simd_size]:

    var rwidth = 1.0 / width
    var frange = Float64(num_speakers) * rwidth
    var rrange = 1.0 / frange

    var aligned_pos_fac = 0.5 * Float64(num_speakers)
    var aligned_pos_const = width * 0.5 + orientation

    var constant = pan * 2.0 * aligned_pos_fac + aligned_pos_const
    chan_pos = SIMD[DType.float64, simd_size](0.0)
    chan_amp = SIMD[DType.float64, simd_size](0.0)
    
    for i in range(num_speakers):
        chan_pos[Int(i)] = (constant - Float64(i)) * rwidth

    chan_pos = (chan_pos - frange * floor(rrange * chan_pos)) * pi

    for i in range(num_speakers):
        if chan_pos[Int(i)] >= pi:
            chan_amp[Int(i)] = 0.0
        else:
            chan_amp[Int(i)] = sin(chan_pos[Int(i)])

    # with more than 4 channels, this SIMD multiplication is inefficient

    return sample * chan_amp

# keeping these around for now

# I am sure there is a better way to do this
# was trying to do it with SIMD
struct PanAz (Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output
    var w: UnsafePointer[MMMWorld]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output
        self.w = w

    fn __repr__(self) -> String:
        return String("PanAz")

    @always_inline
    fn next[N: Int](mut self, sample: Float64, pan: Float64, num_speakers: Int64, width: Float64 = 2.0, orientation: Float64 = 0.5) -> SIMD[DType.float64, N]:
        # translated from SuperCollider

        var rwidth = 1.0 / width
        var frange = Float64(num_speakers) * rwidth
        var rrange = 1.0 / frange

        var aligned_pos_fac = 0.5 * Float64(num_speakers)
        var aligned_pos_const = width * 0.5 + orientation

        var constant = pan * 2.0 * aligned_pos_fac + aligned_pos_const
        chan_pos = SIMD[DType.float64, N](0.0)
        chan_amp = SIMD[DType.float64, N](0.0)
        
        for i in range(num_speakers):
            chan_pos[Int(i)] = (constant - Float64(i)) * rwidth

        chan_pos = (chan_pos - frange * floor(rrange * chan_pos)) / 2.0

        for i in range(num_speakers):
            if chan_pos[Int(i)] >= 0.5:
                chan_amp[Int(i)] = 0.0
            else:
                chan_amp[Int(i)] = self.w[].osc_buffers.read_none(chan_pos[Int(i)], 0)

        # with more than 4 channels, this SIMD multiplication is inefficient

        return sample * chan_amp

struct Pan2(Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output
    var w: UnsafePointer[MMMWorld]
    var gains: SIMD[DType.float64, 2]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output
        self.w = w
        self.gains = SIMD[DType.float64, 2](0.0, 0.0)

    fn __repr__(self) -> String:
        return String("Pan2")

    @always_inline
    fn next(mut self, samples: SIMD[DType.float64, 2], pan: Float64) -> SIMD[DType.float64, 2]:
        # Calculate left and right channel samples based on pan value
        pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
        
        self.gains[0] = self.w[].osc_buffers.at_phase[osc_type=OscType.sine](self.w, linlin(-pan2,-1.0, 1.0, 0.0, 0.25))
        self.gains[1] = self.w[].osc_buffers.at_phase[osc_type=OscType.sine](self.w, linlin(pan2, -1.0, 1.0, 0.0, 0.25))

        samples_out = samples * self.gains
        return samples_out  # Return stereo output as List

struct Splay[num_output_channels: Int = 2, pan_points: Int = 128](Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output
    var w: UnsafePointer[MMMWorld]
    var mul_list: List[SIMD[DType.float64, num_output_channels]]
    var zero: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output
        self.w = w
        self.zero = 0.0

        js = SIMD[DType.float64, self.num_output_channels](0.0, 1.0)
        @parameter
        if self.num_output_channels > 2:
            for j in range(self.num_output_channels):
                js[j] = Float64(j)

        self.mul_list = [SIMD[DType.float64, self.num_output_channels](0.0) for _ in range(self.pan_points)]
        for i in range(self.pan_points):
            pan = Float64(i) * Float64(self.num_output_channels - 1) / Float64(self.pan_points - 1)

            d = abs(pan - js)
            @parameter
            if self.num_output_channels > 2:
                for j in range(self.num_output_channels):
                    if d[j] < 1.0:
                        d[j] = d[j]
                    else:
                        d[j] = 1.0
            
            for j in range(self.num_output_channels):
                self.mul_list[i][j] = cos(d[j] * pi_over_2)
            print("pan point ", i, ": ", self.mul_list[i])

    @always_inline
    fn next(mut self, input: List[Float64]) -> SIMD[DType.float64, self.num_output_channels]:
        out = SIMD[DType.float64, self.num_output_channels](0.0)

        in_len = len(input)
        if in_len == 0:
            return out
        elif in_len == 1:
            out = input[0] * self.mul_list[0]
            return out
        for i in range(in_len):
            out += input[i] * self.mul_list[Int(Float64(i) / Float64(in_len - 1) * Float64(self.pan_points - 1))]
            
        return out