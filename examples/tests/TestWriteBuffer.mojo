
from mmm_audio import *

struct TestWriteBuffer(Copyable,Movable):
    var world: World
    var buf: Buffer
    var linear: Play
    var rec: Recorder[2]
    var m: Messenger
    var counter: Int

    def __init__(out self, world: World):
        self.world = world
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.linear = Play(self.world)
        self.rec = Recorder[2](self.world, Int(self.world[].sample_rate*2.0), self.world[].sample_rate)
        self.m = Messenger(self.world)
        self.counter = 0

    def next(mut self) -> SIMD[DType.float64,2]:
        linear = self.linear.next[1,Interp.linear](self.buf)
        self.rec.write_next(linear)
        if self.counter == Int(self.world[].sample_rate*2.0 + 20000):
            self.rec.buf.write_to_file("tmp/rec_test1.wav")
            # toggle between True and False to test if the file is rotated back to circular after writing
            self.rec.buf.write_circular_buf_to_file(self.rec.write_head, "tmp/rec_test2.wav", -1, True)
            self.rec.buf.write_to_file("tmp/rec_test3.wav")
        self.counter += 1

        return [0.0,0.0]