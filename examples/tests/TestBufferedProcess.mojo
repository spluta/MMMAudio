from mmm_audio import *

###########################################################
#                   Test BufferedProcess                  #
###########################################################
# This test creates a BufferedProcess that multiplies
# the input samples by a factor received from a Messenger.
# Because no windowing is applied and there is no overlap
# (hop_size == window_size), the output samples should
# just be the input samples multiplied by the factor.

# This corresponds to the user defined BufferedProcess.
struct BufferedMultiply(BufferedProcessable):
    var world: World
    var factor: Float64
    var m: Messenger

    fn __init__(out self, world: World):
        self.world = world
        self.factor = 0.5
        self.m = Messenger(self.world)

    fn get_messages(mut self) -> None:
        self.m.update(self.factor,"factor")

    fn next_window(mut self, mut input: List[Float64]) -> None:

        for ref v in input:
            v *= self.factor

# User's Synth
struct TestBufferedProcess(Movable, Copyable):
    var world: World
    var my_buffered_mul: BufferedProcess[BufferedMultiply,1024,1024,input_window_shape=WindowType.rect,output_window_shape=WindowType.rect]
    var input: Float64
    var m: Messenger
    var ps: List[Print]

    fn __init__(out self, world: World):
        self.world = world
        self.input = 0.1
        var multiply_process = BufferedMultiply(self.world)
        self.my_buffered_mul = BufferedProcess[BufferedMultiply,1024,1024,input_window_shape=WindowType.rect,output_window_shape=WindowType.rect](self.world,process=multiply_process^)
        self.m = Messenger(self.world)
        self.ps = List[Print](length=2,fill=Print(self.world))

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.input,"input")
        self.ps[0].next(self.input,"input  ")
        o = self.my_buffered_mul.next(self.input)
        self.ps[1].next(o,"output ")

        return SIMD[DType.float64,2](0.0, 0.0)

