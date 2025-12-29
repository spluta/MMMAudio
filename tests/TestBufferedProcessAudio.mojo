from mmm_src.MMMWorld import *
from mmm_dsp.BufferedProcess import BufferedProcess, BufferedProcessable
from mmm_utils.Messenger import Messenger
from mmm_utils.Print import Print
from mmm_utils.Windows import WindowType
from mmm_dsp.Play import Play
from mmm_utils.functions import select
from mmm_utils.functions import dbamp

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
    var world: UnsafePointer[MMMWorld]
    var m: Messenger
    var vol: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.vol = 0.0
        self.m = Messenger(self.world)

    fn get_messages(mut self) -> None:
        self.m.update(self.vol,"vol")

    fn next_window(mut self, mut input: List[Float64]) -> None:

        amp = dbamp(self.vol)
        for ref v in input:
            v *= amp

# User's Synth
struct TestBufferedProcessAudio(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: Play
    var my_buffered_mul: BufferedProcess[BufferedMultiply,1024,512,0]
    var m: Messenger
    var ps: List[Print]
    var which: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world) 
        var multiply_process = BufferedMultiply(self.world)
        self.my_buffered_mul = BufferedProcess[BufferedMultiply,1024,512,0](self.world,process=multiply_process^)
        self.m = Messenger(self.world)
        self.ps = List[Print](length=2,fill=Print(self.world))
        self.which = 0

    fn next(mut self) -> SIMD[DType.float64,2]:
        i = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        o = self.my_buffered_mul.next(i)
        self.m.update(self.which,"which")
        o = select(self.which,[i,o])
        return SIMD[DType.float64,2](o,o)

