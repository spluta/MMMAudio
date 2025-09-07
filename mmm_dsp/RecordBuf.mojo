from memory import UnsafePointer
from .Buffer import *
from mmm_src.MMMWorld import MMMWorld
from .Osc import Impulse
from mmm_utils.functions import *
from .Env import Env

struct RecordBuf (Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var index: Int64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.index = 0

    fn __repr__(self) -> String:
        return String("RecordBuf")
    
    fn write(mut self, input: Float64, mut buffer: Buffer):
        buffer.write(self.index, input, 0)
        self.index += 1
        if self.index >= Int64(buffer.num_frames):
            self.index = 0

    fn write(mut self, input: List[Float64], mut buffer: Buffer):
        buffer.write(self.index, input, 0)
        self.index += 1
        if self.index >= Int64(buffer.num_frames):
            self.index = 0