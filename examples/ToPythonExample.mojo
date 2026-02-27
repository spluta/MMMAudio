
from mmm_audio import *

struct ToPythonExample(Movable, Copyable):
    var world: World
    var m: Messenger
    var yin: BufferedInput[YIN[1024],1024,512]
    var buf: Buffer
    var play: Play
    var vals: List[Float64]

    fn __init__(out self, world: World):
        self.world = world
        self.m = Messenger(self.world)
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.play = Play(self.world)
        yin = YIN[1024](self.world)
        self.yin = BufferedInput[YIN[1024],1024,512](self.world,yin^)
        self.vals = List[Float64]()
        for i in range(1025):
            self.vals.append(i / 1024.0)

    fn next(mut self) -> SIMD[DType.float64, 2]:

        sig = self.play.next(self.buf)
        self.yin.next(sig)
        self.m.reply_stream("pitch", self.yin.process.pitch)
        self.m.reply_stream("vals", self.vals)
        self.m.reply_stream("bool", random_float64() > 0.5)

        return SIMD[DType.float64, 2](sig, sig)