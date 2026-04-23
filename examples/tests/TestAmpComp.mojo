from mmm_audio import *

comptime num_chans = 2

struct TestAmpComp(Movable, Copyable):
    var world: World
    var buffer: SIMDBuffer[2]
    var amp: Amplitude[2]
    var compress: Compressor[2]

    var play_buf: Play
    fn __init__(out self, world: World):
        self.world = world 
        self.buffer = SIMDBuffer[2].load("resources/Shiverer.wav")

        self.play_buf = Play(self.world)
        self.amp = Amplitude[2](world, 0.01, 0.1)
        self.compress = Compressor[2](world, threshold=-30.0, ratio=10.0, attack=0.05, release=0.5)

    fn next(mut self) -> MFloat[num_chans]:

        sig = self.play_buf.next[num_chans=num_chans](self.buffer, 1.0, True)
        amp = self.amp.next(sig)
        out = self.compress.next(sig)
        self.world[].print(amp, out, self.compress.sidechain, n_blocks = 100)

        return out