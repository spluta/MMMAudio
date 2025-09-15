from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Osc import Impulse

# this really needs to be a global object that everything can access

struct Print(Representable, Copyable, Movable):
    var impulse: Impulse
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.impulse = Impulse(world_ptr)

    fn __repr__(self: Print) -> String:
        return String("Print")

    fn next[T: Writable](mut self, value: T, label: String = "", freq: Float64 = 10.0) -> None:

        if self.impulse.next(freq) > 0.0:
            print(label,value)    