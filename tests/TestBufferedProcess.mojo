from mmm_src.MMMWorld import *
from mmm_dsp.BufferedProcess import BufferedProcess, BufferedProcessable
from mmm_utils.Messengers import Messenger
from mmm_utils.Print import Print

# User created BufferedProcess. This struct's next() function
# is called one time every hop_size samples and is passed a List
# of window_size floats
struct BufferedMultiply[window_size: Int = 1024](BufferedProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var factor: Float64
    var output: List[Float64]
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.factor = 0.5
        self.output = List[Float64](length=window_size, fill=0.0)
        self.m = Messenger(world_ptr)

    # This needs to get called every audio block, otherwise it's not guaranteed that 
    # the beginning of the BufferProcess window and top of audio block will be aligned
    # so the messages might not be retrieved.
    fn get_messages(mut self) -> None:
        self.m.update(self.factor,"factor")

    # Once enough samples are buffered, this function is called.
    # The user can do whatever they want with the input list and
    # then return a list of the same size. The input List is mut
    # so it's not getting copied. It returns (as required by the
    # BufferedProcessable trait) an UnsafePointer to the output list so
    # so that that isn't copied either.
    fn next(mut self, input: List[Float64]) -> UnsafePointer[List[Float64]]:

        @parameter
        for i in range(window_size):
            self.output[i] = input[i] * self.factor

        # Could do an FFT here and get a list of complex numbers,
        # do some processing, then do an IFFT to get back to time domain
        # and return that list of amplitudes.

        # This struct could keep track of previous FFT frames and do
        # something that keeps track of them in sequence.

        return UnsafePointer(to=self.output)


# User's Synth
struct TestBufferedProcess(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var my_buffered_mul: BufferedProcess[BufferedMultiply]
    var input: Float64
    var m: Messenger
    var ps: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.input = 0.1
        var multiply_process = BufferedMultiply[1024](self.world_ptr)
        self.my_buffered_mul = BufferedProcess[BufferedMultiply,1024,512](self.world_ptr,process=multiply_process^)
        self.m = Messenger(world_ptr)
        self.ps = List[Print](length=2,fill=Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.input,"input")
        self.ps[0].next(self.input,"input  ")
        o = self.my_buffered_mul.next(self.input)
        self.ps[1].next(o,"output ")

        return SIMD[DType.float64,2](0.0, 0.0)

