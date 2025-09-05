from mmm_utils.functions import clip
from math import sqrt
from sys import simdwidthof

struct Pan2 (Representable, Movable, Copyable):
    var output: List[Float64]  # Output list for stereo output

    fn __init__(out self):
        self.output = List[Float64](0.0, 0.0)  # Initialize output list for stereo output

    fn __repr__(self) -> String:
        return String("Pan2")

    fn next(mut self, sample: Float64, mut pan: Float64) -> List[Float64]:
        # Calculate left and right channel samples based on pan value
        pan = clip(pan, -1.0, 1.0)  # Ensure pan is set and clipped before processing
        self.output[0] = sample * ((1.0 - pan) * 0.5) ** 0.5
        self.output[1] = sample * ((1.0 + pan) * 0.5) ** 0.5

        return self.output  # Return stereo output as List

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
        
        # Apply gains in parallel
        return samples * gains