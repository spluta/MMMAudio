from mmm_utils.functions import clip
from math import sqrt, floor
from bit import next_power_of_two
from sys import simd_width_of
from mmm_utils.functions import *

struct Pan2 (Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output

    fn __init__(out self):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output

    fn __repr__(self) -> String:
        return String("Pan2")

    # fn next(mut self, sample: Float64, mut pan: Float64) -> List[Float64]:
    #     # Calculate left and right channel samples based on pan value
    #     pan = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
    #     self.output[0] = sample * ((1.0 - pan) * 0.5) ** 0.5
    #     self.output[1] = sample * ((1.0 + pan) * 0.5) ** 0.5

    #     return self.output  # Return stereo output as List

    fn next(mut self, sample: Float64, mut pan: Float64) -> List[Float64]:
        # Calculate left and right channel samples based on pan value
        pan = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing

        # Create SIMD vector with the sample duplicated
        var samples = SIMD[DType.float64, 2](sample, sample)
        
        # Create gain vector [left_gain, right_gain]
        var gains = SIMD[DType.float64, 2](
            sqrt((1.0 - pan) * 0.5),  # left gain
            sqrt((1.0 + pan) * 0.5)   # right gain
        )
        samples = samples * gains
        
        # Apply gains in parallel
        return [samples[0], samples[1]]  # Return stereo output as List

    fn next_simd(mut self, sample: Float64, mut pan: Float64) -> SIMD[DType.float64, 2]:
        # Calculate left and right channel samples based on pan value
        pan = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing

        # Create SIMD vector with the sample duplicated
        var samples = SIMD[DType.float64, 2](sample, sample)
        
        # Create gain vector [left_gain, right_gain]
        var gains = SIMD[DType.float64, 2](
            sqrt((1.0 - pan) * 0.5),  # left gain
            sqrt((1.0 + pan) * 0.5)   # right gain
        )
        samples = samples * gains
        
        # Apply gains in parallel
        return samples  # Return stereo output as List

# I am sure there is a better way to do this
# was trying to do it with SIMD
struct PanAz (Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output

    fn __init__(out self):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output

    fn __repr__(self) -> String:
        return String("PanAz")

    fn next[num_simd: Int](mut self, sample: Float64, pan: Float64, num_speakers: Int) -> SIMD[DType.float64, num_simd]:
        # Calculate left and right channel samples based on pan value
        pan_clipped = clip(pan, 0.0, 1.0)  # Ensure pan is set and clipped before processing

        num_speakers2 = max(2, num_speakers)

        pan_div = 1.0 / Float64(num_speakers2)

        # Create SIMD vector with the sample duplicated
        var samples = SIMD[DType.float64, num_simd](sample)

        # Create gain vector [left_gain, right_gain]
        var gains = SIMD[DType.float64, num_simd](0.0)

        which_div = floor(pan_clipped * Float64(num_speakers2))

        if which_div >= Float64(num_speakers2):
            gains[Int(num_speakers2 - 1)] = 1.0
        else:
            p0 = pan_div * which_div
            p1 = pan_div * (which_div + 1)

            sp2 = Int(which_div + 1) % num_speakers2
            gains[Int(which_div)] = linlin(pan_clipped, p0, p1, 1.0, 0.0) ** 0.5
            gains[sp2] = linlin(pan_clipped, p0, p1, 0.0, 1.0) ** 0.5

        samples = samples * gains
        
        # Apply gains in parallel
        return samples  # Return stereo output as List