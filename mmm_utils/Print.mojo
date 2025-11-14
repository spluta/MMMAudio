from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Osc import Impulse

struct Print(Representable, Copyable, Movable):
    """
    A struct for printing values in the MMMWorld environment.
    """
    var impulse: Impulse
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """
        Initialize the Print struct.
        """
        self.world_ptr = world_ptr
        self.impulse = Impulse(world_ptr)

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

    # fn next[T: Writable](mut self, *value: T) -> None:
    #     """
    #     Print the value at a given frequency.

    #     Args:
    #         value: The value to print.
    #         label: An optional label to prepend to the printed value.
    #         freq: The frequency (in Hz) at which to print the value.
    #     """
    #     if self.impulse.next_bool(self.freq):
    #         for v in value:
    #             print(v, end=" ")
    #         print()