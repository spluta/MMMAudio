from mmm_utils.functions import clip, linlin
from mmm_src.MMMWorld import MMMWorld
from math import sqrt, floor, cos, pi, sin
from bit import next_power_of_two
from sys import simd_width_of
from mmm_utils.functions import *

@always_inline
fn pan2(samples: Float64, pan: Float64) -> SIMD[DType.float64, 2]:
    """
    Simple constant power panning function.
    Args:
        samples: Mono input sample
        pan: Pan value from -1.0 (left) to 1.0 (right)
    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """

    var pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    var gains = SIMD[DType.float64, 2](-pan2, pan2)

    samples_out = samples * sqrt((1 + gains) * 0.5)
    return samples_out  # Return stereo output as List

@always_inline
fn pan2(samples: SIMD[DType.float64, 2], pan: Float64) -> SIMD[DType.float64, 2]:
    """
    Simple constant power panning function for stereo samples.
    Args:
        samples: Stereo input sample
        pan: Pan value from -1.0 (left) to 1.0 (right)
    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """
    var pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    var gains = SIMD[DType.float64, 2](-pan2, pan2)

    samples_out = samples * sqrt((1 + gains) * 0.5)
    return samples_out  # Return stereo output as List

@always_inline
fn splay(input: List[Float64], w: UnsafePointer[MMMWorld]) -> SIMD[DType.float64, 2]:
    """
    Splay multiple input channels into stereo output.
    Args:
        input: List of input samples from multiple channels
        w: Pointer to MMMWorld containing the pan_window
    Returns:
        Stereo output as SIMD[DType.float64, 2].
    """
    num_input_channels = len(input)
    out = SIMD[DType.float64, 2](0.0)

    for i in range(num_input_channels):
        if num_input_channels == 1:
            out = input[0] * SIMD[DType.float64, 2](0.7071, 0.7071)
        else:
            pan = Float64(i) / Float64(num_input_channels - 1)

            out += input[i] * w[].pan_window[Int(pan * Float64(w[].pan_window.__len__() - 1))]
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

    return sample * chan_amp

alias pi_over_2 = pi / 2.0

struct SplayN[num_output_channels: Int = 2, pan_points: Int = 128](Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output
    var w: UnsafePointer[MMMWorld]
    var mul_list: List[SIMD[DType.float64, num_output_channels]]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output
        self.w = w

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




# from memory import UnsafePointer
# from gpu import thread_idx, block_dim, block_idx
# from gpu.host import DeviceContext
# from testing import assert_equal

# @always_inline
# fn splay_gpu[SIZE: Int = 1000](input: List[Float64], w: UnsafePointer[MMMWorld]) -> SIMD[DType.float64, 2]:

#     alias BLOCKS_PER_GRID = 1
#     alias THREADS_PER_BLOCK = SIZE
#     alias dtype = DType.float32

#     fn splay_thread(
#         output: UnsafePointer[Scalar[dtype]],
#         a: UnsafePointer[Scalar[dtype]],
#     ):
#         i = thread_idx.x
#         if i < SIZE:
#             output[i] = a[i] + 10

#     num_input_channels = len(input)
#     try:
#         with DeviceContext() as ctx:
#             out_gpu = ctx.enqueue_create_buffer[dtype](SIZE)
#             a = ctx.enqueue_create_buffer[dtype](SIZE)

#             out_gpu.enqueue_fill(0)
#             a.enqueue_fill(0)
            
#             with a.map_to_host() as a_host:
#                 for i in range(SIZE):
#                     a_host[i] = Float32(input[i])

#             ctx.enqueue_function_checked[splay_thread, splay_thread](
#                 out_gpu,
#                 a,
#                 SIZE,
#                 grid_dim=BLOCKS_PER_GRID,
#                 block_dim=SIZE,
#             )
#     except _:
#         print("no")
#         return SIMD[DType.float64, 2](0.0)
#     out = SIMD[DType.float64, 2](0.0)

#     for i in range(num_input_channels):
#         if num_input_channels == 1:
#             out = input[0] * SIMD[DType.float64, 2](0.7071, 0.7071)
#         else:
#             pan = Float64(i) / Float64(num_input_channels - 1)

#             out += input[i] * w[].pan_window[Int(pan * Float64(len(w[].pan_window) - 1))]
#     return out



# fn create_splay_table[num_output_channels: Int, pan_points: Int]() -> List[SIMD[DType.float64, num_output_channels]]:
#     js = SIMD[DType.float64, num_output_channels](0.0, 1.0)
#     @parameter
#     if num_output_channels > 2:
#         for j in range(num_output_channels):
#             js[j] = Float64(j)

#     mul_list = [SIMD[DType.float64, num_output_channels](0.0) for _ in range(pan_points)]
#     for i in range(pan_points):
#         pan = Float64(i) * Float64(num_output_channels - 1) / Float64(pan_points - 1)

#         d = abs(pan - js)
#         @parameter
#         if num_output_channels > 2:
#             for j in range(num_output_channels):
#                 if d[j] < 1.0:
#                     d[j] = d[j]
#                 else:
#                     d[j] = 1.0
        
#         for j in range(num_output_channels):
#             mul_list[i][j] = cos(d[j] * pi_over_2)
#     return mul_list^

# @always_inline
# fn splay(input: List[Float64], w: UnsafePointer[MMMWorld]) -> SIMD[DType.float64, 2]:
#     alias splay_table = create_splay_table[2, 128]()
#     num_input_channels = len(input)
#     out = SIMD[DType.float64, 2](0.0)

#     for i in range(num_input_channels):
#         if num_input_channels == 1:
#             out = input[0] * SIMD[DType.float64, 2](0.7071, 0.7071)
#         else:
#             pan = Float64(i) / Float64(num_input_channels - 1)

#             out += input[i] * splay_table[Int(pan * Float64(len(splay_table) - 1))]
#     return out

# fn splayN[num_output_channels: Int](input: List[Float64], w: UnsafePointer[MMMWorld]) -> SIMD[DType.float64, num_output_channels]:
#     num_input_channels = len(input)
#     out = SIMD[DType.float64, num_output_channels](0.0)

#     @parameter
#     if num_output_channels == 2:
#         temp = splay(input, w)
#         out[0] = temp[0]
#         out[1] = temp[1]
#     else:
#         low = 0
#         for i in range(num_output_channels):
#             hi = low + num_input_channels // num_output_channels

#     spans = List[Int](capacity)

