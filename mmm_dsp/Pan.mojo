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

    fn next(mut self, sample: Float64, mut pan: Float64) -> SIMD[DType.float64, 2]:
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

    fn next[N: Int](mut self, sample: Float64, pan: Float64, num_speakers: Int) -> SIMD[DType.float64, N]:
        # Calculate left and right channel samples based on pan value
        pan_wrapped = wrap(pan, 0.0, 1.0)  # Ensure pan is set and wrapped between 0.0 and 1.0

        num_speakers_b = max(1, num_speakers)

        pan_div = 1.0 / Float64(num_speakers_b)

        # Create SIMD vector with the sample duplicated
        var samples = SIMD[DType.float64, 2](sample)

        # Create gain vector [left_gain, right_gain]
        var gains = SIMD[DType.float64, 2](pan_wrapped % pan_div * Float64(num_speakers_b))
        gains[0] = 1.0-gains[0]
        # print("pan_wrapped: " + String(pan_wrapped) + " gains: " + String(gains))

        sp1 = floor(pan_wrapped * Float64(num_speakers_b))
        sp2 = Int(sp1 + 1) % num_speakers

        samples = samples * sqrt(gains)

        out = SIMD[DType.float64, N](0.0)
        out[Int(sp1)] = samples[0]
        out[Int(sp2)] = samples[1]
        
        # Apply gains in parallel
        return out  # Return stereo output as List