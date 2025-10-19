from mmm_utils.functions import clip
from mmm_src.MMMWorld import MMMWorld
from math import sqrt, floor
from bit import next_power_of_two
from sys import simd_width_of
from mmm_utils.functions import *

struct Pan2 (Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output
    var world_ptr: UnsafePointer[MMMWorld]
    var gains: SIMD[DType.float64, 2]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output
        self.world_ptr = world_ptr
        self.gains = SIMD[DType.float64, 2](0.0, 0.0)

    fn __repr__(self) -> String:
        return String("Pan2")

    @always_inline
    fn next(mut self, samples: SIMD[DType.float64, 2], pan: Float64) -> SIMD[DType.float64, 2]:
        # Calculate left and right channel samples based on pan value
        pan2 = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
        
        self.gains[0] = sqrt((1.0 - pan2) * 0.5)  # left gain
        self.gains[1] = sqrt((1.0 + pan2) * 0.5)   # right gain

        samples_out = samples * self.gains
        return samples_out  # Return stereo output as List


# I am sure there is a better way to do this
# was trying to do it with SIMD
struct PanAz (Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output
        self.world_ptr = world_ptr

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
                chan_amp[Int(i)] = self.world_ptr[0].osc_buffers.read_lin(chan_pos[Int(i)], 0)

        # with more than 4 channels, this SIMD multiplication is inefficient

        return sample * chan_amp

@always_inline
fn splay[
    width: Int, //
](samples: SIMD[DType.float64, width]) -> SIMD[DType.float64, 2]:
    var gains = SIMD[DType.float64, 2](0.0, 0.0)
    var out = SIMD[DType.float64, 2](0.0, 0.0)

    @parameter
    fn get_pan(i: Int) -> Float64:
        if width == 1:
            return 0.0
        else:
            return Float64(i) * 2.0 / Float64(width-1) - 1.0  # pan from -1.0 to 1.0
    
    @parameter
    for i in range(width):
        alias pan = get_pan(i)
        gains[0] = sqrt((1.0 - pan) * 0.5)  # left gain
        gains[1] = sqrt((1.0 + pan) * 0.5)   # right gain

        out = out + samples[i] * gains 

    return out

@always_inline
fn splay[
    num_samples: Int, //
](samples: List[Float64]) -> SIMD[DType.float64, 2]:
    var gains = SIMD[DType.float64, 2](0.0, 0.0)
    var out = SIMD[DType.float64, 2](0.0, 0.0)

    @parameter
    fn get_pan(i: Int) -> Float64:
        if num_samples == 1:
            return 0.0
        else:
            return Float64(i) * 2.0 / Float64(num_samples-1) - 1.0  # pan from -1.0 to 1.0

    @parameter
    for i in range(num_samples):
        alias pan = get_pan(i)
        gains[0] = sqrt((1.0 - pan) * 0.5)  # left gain
        gains[1] = sqrt((1.0 + pan) * 0.5)   # right gain

        out = out + samples[i] * gains 

    return out