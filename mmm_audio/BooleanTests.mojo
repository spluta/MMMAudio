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

struct Changed(Movable, Copyable):
    """Detect changes in a Bool, Int, or Float64 value."""
    var last_bool: Bool  # Store the last value
    var last_float: Float64  # Store the last value
    var last_int: Int  # Store the last value

    fn __init__(out self, initial: Bool = False):
        """Initialize the Changed struct.

        Args:
            initial: The initial value to compare against.
        """
        self.last_bool = initial  # Initialize last value
        self.last_float = -1.0
        self.last_int = -1

    fn __init__(out self, initial: Int = 0):
        self.last_bool = False  # Initialize last value
        self.last_float = -1.0
        self.last_int = initial

    fn __init__(out self, initial: Float64 = 0.0):
        self.last_bool = False  # Initialize last value
        self.last_float = initial
        self.last_int = -1

    fn next(mut self, val: Bool) -> Bool:
        """Check if the value has changed.
        
        Args:
            val: The current value to check. Bool, Int, and Float64 types are supported.
        
        Returns:
            True if the value has changed since the last check, False otherwise.
        """
        if val != self.last_bool:
            self.last_bool = val  # Update last value
            return True
        return False
    
    fn next(mut self, val: Int) -> Bool:
        if val != self.last_int:
            self.last_int = val  # Update last value
            return True
        return False

    fn next(mut self, val: Float64) -> Bool:
        if val != self.last_float:
            self.last_float = val  # Update last value
            return True
        return False