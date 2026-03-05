

from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestImpulse(Movable, Copyable):
    var world: World
    var synth: Impulse[2]
    var trig: SIMD[DType.bool, 2]
    var freqs: SIMD[DType.float64, 2]
    var messenger: Messenger
    var ints: List[Int]
    var phase_offsets: SIMD[DType.float64, 2]

    fn __init__(out self, world: World):
        self.world = world
        self.synth = Impulse[2](self.world)
        self.trig = SIMD[DType.bool, 2](fill=True)
        self.freqs = SIMD[DType.float64, 2](5,5)
        self.messenger = Messenger(world)
        self.ints = []
        self.phase_offsets = SIMD[DType.float64, 2](0.0, 0.0)


    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.messenger.notify_update(self.ints, "trig"):
            for i in range(min(2, len(self.ints))):
                self.trig[i] = self.ints[i] > 0
        else:
            self.trig = SIMD[DType.bool, 2](fill = False)

        offsets = [0.0,0.0]
        if self.messenger.notify_update(offsets, "phase_offsets"):
            for i in range(min(2, len(offsets))):
                self.phase_offsets[i] = offsets[i]

        freqs = List[Float64]()
        if self.messenger.notify_update(freqs, "freqs"):
            for i in range(min(2, len(freqs))):
                self.freqs[i] = freqs[i]

        sample = self.synth.next(self.freqs, self.phase_offsets, self.trig)  # Get the next sample from the synth
        return sample * 0.2  # Get the next sample from the synth