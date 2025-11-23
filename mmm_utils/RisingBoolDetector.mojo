struct RisingBoolDetector[N: Int = 1](Representable, Movable, Copyable):
    """A simple rising edge detector for boolean triggers."""
    var state: SIMD[DType.bool, N]

    fn __init__(out self):
        self.state = SIMD[DType.bool, N](fill=False)
        
    fn __repr__(self) -> String:
        return String("RisingBoolDetector")
    
    fn next(mut self, trig: SIMD[DType.bool, N]) -> SIMD[DType.bool, N]:
        """Check if a trigger has occurred (rising edge) per SIMD lane."""
        
        var rising = trig & ~self.state # The & and ~ operators work element-wise on SIMD boolean vectors, so this computes the rising edge detection for all lanes simultaneously without any loops.
        
        self.state = trig
        return rising