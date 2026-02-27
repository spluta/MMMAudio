from mmm_audio import *

struct Spectrogram(FFTProcessable):
    var world: World
    var m: Messenger
    var mags: List[Float64]

    fn __init__(out self, world: World, fftsize: Int = 1024):
        self.world = world
        self.m = Messenger(world)
        self.mags = List[Float64](length=(fftsize // 2) + 1, fill=0.0)

    fn next_frame(mut self, mut mags: List[Float64], mut freqs: List[Float64]):
        for i in range(len(mags)):
            self.mags[i] = mags[i]
    
    fn send_streams(mut self) -> None:
        self.m.reply_stream("mags", self.mags)

struct SpectrogramExample(Movable, Copyable):
    var world: World
    var buf: Buffer
    var play: Play
    var m: Messenger
    var fftproces: FFTProcess[Spectrogram]

    fn __init__(out self, world: World):
        self.world = world
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.play = Play(world)
        self.m = Messenger(world)
        self.fftproces = FFTProcess(world, Spectrogram(world))

    fn next(mut self) -> MFloat[2]:
        sig = self.play.next(self.buf)
        _ = self.fftproces.next(sig)
        return sig