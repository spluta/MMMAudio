from mmm_audio import *

comptime num_chans = 2

struct TestAmplitude(Movable, Copyable):
    var world: World
    var buffer: SIMDBuffer[2]
    var amp: Amplitude[2]
    var compress: Compressor[2]

    var play_buf: Play
    fn __init__(out self, world: World):
        self.world = world 
        self.buffer = SIMDBuffer[2].load("resources/Shiverer.wav")

        self.play_buf = Play(self.world)
        self.amp = Amplitude[2](world)
        self.compress = Compressor[2](world)

    fn next(mut self) -> MFloat[num_chans]:

        out = self.play_buf.next[num_chans=num_chans](self.buffer, 1.0, True)
        amp = self.amp.next(out, 0.1, 0.1)
        self.world[].print(amp, self.compress.next(amp, threshold=-40.0, ratio=4.0, attack=0.01, release=0.1))

        return 0.0