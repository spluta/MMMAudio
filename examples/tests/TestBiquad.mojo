from mmm_audio import *

struct TestBiquad(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var noise: WhiteNoise[1]  # White noise source
    var filts: List[Biquad]
    var messenger: Messenger
    var cutoff: Float64
    var q: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.noise = WhiteNoise[1]()  # Initialize white noise
        self.messenger = Messenger(self.world)
        self.filts = List[Biquad](capacity=2)
        self.cutoff = 1000.0
        self.q = 1.0
        for i in range(2):
            self.filts[i] = Biquad(self.world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.cutoff, "cutoff")
        self.messenger.update(self.q, "q")
        
        # Generate white noise
        sample = self.noise.next()
        
        # Split to stereo: left=LPF, right=HPF
        outs = SIMD[DType.float64, 2](0.0, 0.0)
        outs[0] = self.filts[0].lpf(sample, self.cutoff, self.q)
        outs[1] = self.filts[1].hpf(sample, self.cutoff, self.q)
        return outs * 0.2