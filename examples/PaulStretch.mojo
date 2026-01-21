from mmm_audio import *

from random import random_float64

# this really should have a window size of 8192 or more, but the numpy FFT seems to barf on this
comptime window_size = 2048
comptime hop_size = window_size // 2

struct PaulStretchWindow[window_size: Int](FFTProcessable):
    var world: LegacyUnsafePointer[MMMWorld]
    var m: Messenger

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.m = Messenger(self.world)

    fn get_messages(mut self) -> None:
        pass

    fn next_stereo_frame(mut self, mut mags: List[SIMD[DType.float64, 2]], mut phases: List[SIMD[DType.float64, 2]]) -> None:
        for ref p in phases:
            p = SIMD[DType.float64, 2](random_float64(0.0, 2.0 * 3.141592653589793), random_float64(0.0, 2.0 * 3.141592653589793))

# User's Synth
struct PaulStretch(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var buffer: Buffer
    var saw: LFSaw
    var paul_stretch: FFTProcess[PaulStretchWindow[window_size],window_size,hop_size,WindowType.sine,WindowType.sine]
    var m: Messenger
    var dur_mult: Float64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.saw = LFSaw(self.world)

        self.paul_stretch = FFTProcess[
                PaulStretchWindow[window_size],
                window_size,
                hop_size,
                WindowType.sine,
                WindowType.sine
            ](self.world,process=PaulStretchWindow[window_size](self.world))

        self.m = Messenger(self.world)
        self.dur_mult = 40.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        phase = self.saw.next(speed)*0.5 + 0.5
        o = self.paul_stretch.next_from_stereo_buffer(self.buffer, phase, 0)
        return o

