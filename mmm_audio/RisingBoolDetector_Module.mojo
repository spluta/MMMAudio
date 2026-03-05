from mmm_audio import *

struct RisingBoolDetector[num_chans: Int = 1](Representable, Movable, Copyable):
    """A simple rising edge detector for boolean triggers. Outputs a boolean True trigger when the input transitions from False to True.
    
    Parameters:
        num_chans: The size of the SIMD vector - defaults to 1.
    """
    var state: SIMD[DType.bool, Self.num_chans]

    fn __init__(out self):
        self.state = SIMD[DType.bool, Self.num_chans](fill=False)
        
    fn __repr__(self) -> String:
        return String("RisingBoolDetector")
    
    fn next(mut self, trig: SIMD[DType.bool, Self.num_chans]) -> SIMD[DType.bool, Self.num_chans]:
        """Check if a trigger has occurred (rising edge) per SIMD lane.
        
        Args:
            trig: The input boolean SIMD vector to check for rising edges. Each SIMD lane is processed independently.

        Returns:
            A SIMD boolean vector outputting single sample boolean triggers which indicate the rising edge detection for each lane.
        """
        
        var rising = trig & ~self.state # The & and ~ operators work element-wise on SIMD boolean vectors, so this computes the rising edge detection for all lanes simultaneously without any loops.
        
        self.state = trig
        return rising

struct ToggleBool[num_chans: Int = 1](Representable, Movable, Copyable):
    """A rising edge detector for boolean triggers.
    
    Parameters:
        num_chans: The size of the SIMD vector - defaults to 1.
    """
    var state: SIMD[DType.bool, Self.num_chans]
    var rbd: RisingBoolDetector[Self.num_chans]

    fn __init__(out self):
        """
        Initialize the ToggleBool struct.
        """
        self.state = SIMD[DType.bool, Self.num_chans](fill=False)
        self.rbd = RisingBoolDetector[Self.num_chans]()
        
    fn __repr__(self) -> String:
        return String("RisingBoolDetector")
    
    fn next(mut self, trig: SIMD[DType.bool, Self.num_chans]) -> SIMD[DType.bool, Self.num_chans]:
        """Check if a trigger has occurred (rising edge) per SIMD lane.
        
        Args:
            trig: The input boolean SIMD vector to check for rising edges. Each SIMD lane is processed independently.

        Returns:
            A SIMD boolean vector indicating the toggled state for each lane.
        """
        
        var rising = self.rbd.next(trig)

        if rising:
            self.state = ~self.state

        return self.state