from mmm_audio import *

struct RisingBoolDetector[num_chans: Int = 1](Representable, Movable, Copyable):
    """A simple rising edge detector for boolean triggers. Outputs a boolean True trigger when the input transitions from False to True.
    
    Parameters:
        num_chans: The size of the SIMD vector - defaults to 1.
    """
    var state: MBool[Self.num_chans]

    fn __init__(out self):
        self.state = MBool[Self.num_chans](fill=False)
        
    fn __repr__(self) -> String:
        return String("RisingBoolDetector")
    
    fn next(mut self, trig: MBool[Self.num_chans]) -> MBool[Self.num_chans]:
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
    var state: MBool[Self.num_chans]
    var rbd: RisingBoolDetector[Self.num_chans]

    fn __init__(out self):
        """
        Initialize the ToggleBool struct.
        """
        self.state = MBool[Self.num_chans](fill=False)
        self.rbd = RisingBoolDetector[Self.num_chans]()
        
    fn __repr__(self) -> String:
        return String("RisingBoolDetector")
    
    fn next(mut self, trig: MBool[Self.num_chans]) -> MBool[Self.num_chans]:
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

struct Changed[T: Equatable & ImplicitlyCopyable](Movable, Copyable):
    """Detect changes in a Bool, Int, or Float64 value.
    
    Parameters:
        T: The type of value to track for changes. The is required when declared as a struct member. This will usually be Bool, Int, Float64, or SIMD vector. ```Changed[Bool]``` will track changes in boolean values, ```Changed[Int]``` will track changes in integer values, and ```Changed[Float64]``` will track changes in floating-point values.
    """
    var last: Self.T  # Store the last value

    fn __init__(out self, initial: Self.T):
        """Initialize the Changed struct.

        Args:
            initial: The initial value to compare against.
        """
        self.last = initial  # Initialize last value

    fn next(mut self, val: Self.T) -> Bool:
        """Check if the value has changed.
        
        Args:
            val: The current value to check. Bool, Int, and Float64 types are supported.
        
        Returns:
            True if the value has changed since the last check, False otherwise.
        """
        if val != self.last:
            self.last = val  # Update last value
            return True
        return False

struct ChangedSIMD[type: DType, size: Int,//](Movable, Copyable):
    """Detect element-wise changes in a SIMD vector value.
    
    Parameters:
        type: The DType of the SIMD vector elements (e.g., DType.float32, DType.int64, DType.bool).
        size: The number of elements in the SIMD vector.
    """
    var last: SIMD[Self.type, Self.size]  # Store the last value

    fn __init__(out self, initial: SIMD[Self.type, Self.size]):
        """Initialize the ChangedSIMD struct.

        Args:
            initial: The initial SIMD vector value to compare against.
        """
        self.last = initial

    fn next(mut self, val: SIMD[Self.type, Self.size]) -> SIMD[DType.bool, Self.size]:
        """Check which elements in the SIMD vector have changed.
        
        Args:
            val: The current SIMD vector value to check.
        
        Returns:
            A boolean SIMD vector where True indicates the element changed.
        """
        var changed = val.ne(self.last)
        self.last = val
        return changed