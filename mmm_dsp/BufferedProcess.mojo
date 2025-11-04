from mmm_src.MMMWorld import *
from mmm_utils.Print import Print

# Trait for processes users write that are intended for BufferedProcess
trait BufferedProcessable(Movable, Copyable):
    fn next(mut self, input: List[Float64]) -> UnsafePointer[List[Float64]]:...
    fn get_messages(mut self) -> None:...

# MMMAudio provided BufferedProcess struct that handles buffering, window size, and hop size
struct BufferedProcess[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window: Optional[Int] = None, output_window: Optional[Int] = None](Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var input_buffer: List[Float64]
    var output_buffer: List[Float64]
    var input_buffer_write_head: Int
    var read_head: Int64
    var hop_counter: Int64
    var process: T
    var output_buffer_write_head: Int64
    var p: Print

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], var process: T):
        self.world_ptr = world_ptr
        self.input_buffer_write_head = 0
        self.output_buffer_write_head = 0
        self.hop_counter = 0
        self.read_head = 0
        self.process = process^
        # Times two because it's a circle buffer
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.output_buffer = List[Float64](length=window_size, fill=0.0)
        self.p = Print(world_ptr=self.world_ptr)


    fn next(mut self, input: Float64) -> Float64:

        if self.world_ptr[].top_of_block:
            self.process.get_messages()

        self.input_buffer[self.input_buffer_write_head] = input
        self.input_buffer[self.input_buffer_write_head + window_size] = input
        self.input_buffer_write_head = (self.input_buffer_write_head + 1) % window_size
        # self.p.next(self.hop_counter,"hop counter: ")
        if self.hop_counter == 0:
            # If desired, apply input_window here (not yet implemented)
            outlist_ptr = self.process.next(self.input_buffer[self.input_buffer_write_head+1:self.input_buffer_write_head + window_size + 1])
            @parameter
            for i in range(window_size):
                # If desired, apply output_window here (not yet implemented)
                self.output_buffer[(self.output_buffer_write_head + i) % window_size] += outlist_ptr[][i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size

        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.output_buffer[self.read_head]
        self.output_buffer[self.read_head] = 0.0
        self.read_head = (self.read_head + 1) % window_size
        return outval