# Trait for processes users write that are intended for BufferedProcess
trait BufferProcessable(Movable, Copyable):
    # [TODO] Would love to return a reference to this list, not a copy.
    fn next(mut self, input: List[Float64]) -> UnsafePointer[Float64]:...

# MMMAudio provided BufferedProcess struct that handles buffering and hop size
struct BufferedProcess[T: BufferProcessable](Movable, Copyable):
    var window_size: Int
    var hop_size: Int
    var input_buffer: List[Float64]
    var output_buffer: List[Float64]
    var input_buffer_write_head: Int
    var read_head: Int
    var hop_counter: Int8
    var process: T
    var output_buffer_write_head: Int

    fn __init__(out self, window_size: Int, hop_size: Int, var process: T):
        self.window_size = window_size
        self.hop_size = hop_size
        self.input_buffer_write_head = 0
        self.output_buffer_write_head = 0
        self.hop_counter = 0
        self.read_head = 0
        self.process = process^
        # Times two because it's a circle buffer
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.output_buffer = List[Float64](length=window_size, fill=0.0)


    fn next(mut self, input: Float64) -> Float64:

        self.input_buffer[self.input_buffer_write_head] = input
        self.input_buffer[self.input_buffer_write_head + self.window_size] = input
        self.input_buffer_write_head = (self.input_buffer_write_head + 1) % self.window_size
        self.hop_counter += 1
        if self.hop_counter >= self.hop_size:
            outlist = self.process.next(self.input_buffer[self.input_buffer_write_head+1:self.input_buffer_write_head + self.window_size + 1])
            for i in range(self.window_size):
                self.output_buffer[(self.output_buffer_write_head + i) % self.window_size] += outlist[i]
            self.output_buffer_write_head = (self.output_buffer_write_head + self.hop_size) % self.window_size
            self.hop_counter = 0

        outval = self.output_buffer[self.read_head]
        self.read_head = (self.read_head + 1) % self.window_size
        return outval

# User created BufferedProcess. This struct's next() function
# is called one time every hop_size samples and is passed a List
# of window_size floats
struct BufferedMultiply(BufferProcessable):
    var factor: Float64
    var output: List[Float64]

    fn __init__(out self, window_size: Int, factor: Float64):
        self.factor = factor
        self.output = List[Float64](length=window_size, fill=0.0)

    # Once enough samples are buffered, this function is called.
    # The user can do whatever they want with the input list and
    # then return a list of the same size. The input List is mut
    # so it's not getting copied. 
    fn next(mut self, input: List[Float64]) -> UnsafePointer[Float64]:
        for i in range(len(input)):
            self.output[i] = input[i] * self.factor

        # Could do an FFT here and get a list of complex numbers,
        # do some processing, then do an IFFT to get back to time domain
        # and return that list of amplitudes.
        p = UnsafePointer(to=self.output[0])
        return p

# User's Synth

struct MySynth(Movable, Copyable):
    var my_buffered_mul: BufferedProcess[BufferedMultiply]

    fn __init__(out self):
        var multiply_process = BufferedMultiply(window_size=512, factor=0.5)
        self.my_buffered_mul = BufferedProcess[BufferedMultiply](window_size=512, hop_size=128, process=multiply_process^)

    fn next(mut self, input: Float64) -> Float64:
        return self.my_buffered_mul.next(input)