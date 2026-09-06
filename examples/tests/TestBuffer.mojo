
from mmm_audio import *

struct TestBuffer(Copyable,Movable):
    var world: World
    var buf: Buffer
    var none: Play
    var linear: Play
    var quad: Play
    var cubic: Play
    var lagrange: Play
    var sinc: Play
    var which: Float64
    var m: Messenger

    def __init__(out self, world: World):
        self.world = world
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.none = Play(self.world)
        self.linear = Play(self.world)
        self.quad = Play(self.world)
        self.cubic = Play(self.world)
        self.lagrange = Play(self.world)
        self.sinc = Play(self.world)
        self.which = 0.0
        self.m = Messenger(self.world)

    def next(mut self) -> SIMD[DType.float64,2]:

        self.m.update("which", self.which) 
        var rate = self.world[].mouse_x() * 20000

        var none = self.none.next[1,Interp.none](self.buf)
        var linear = self.linear.next[1,Interp.linear](self.buf)
        var quad = self.quad.next[1,Interp.quad](self.buf)
        var cubic = self.cubic.next[1,Interp.cubic](self.buf)
        var lagrange = self.lagrange.next[1,Interp.lagrange4](self.buf)
        var sinc = self.sinc.next[1,Interp.sinc](self.buf, rate)
        var out = select(self.which, none,linear,quad,cubic,lagrange,sinc)

        return out