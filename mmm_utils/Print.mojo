from mmm_src.MMMWorld_Module import MMMWorld
from mmm_dsp.Oscillators import Impulse

struct Print(Representable, Copyable, Movable):
    """
    A struct for printing values in the MMMWorld environment.
    """
    var impulse: Impulse
    var world: UnsafePointer[MMMWorld]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        """
        Initialize the Print struct.
        """
        self.world = world
        self.impulse = Impulse(world)

    fn __repr__(self: Print) -> String:
        return String("Print")

    fn next[T: Writable](mut self, value: T, label: Optional[String] = None, freq: Float64 = 10.0) -> None:
        """
        Print the value at a given frequency.

        Args:
            value: The value to print.
            label: An optional label to prepend to the printed value.
            freq: The frequency (in Hz) at which to print the value.
        """
        if self.impulse.next_bool(freq):
            if label:
                print(label.value() + ": ", value)
            else:
                print(value)