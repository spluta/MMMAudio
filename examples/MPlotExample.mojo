from mmm_audio import *

struct MPlotExample(Representable, Movable, Copyable):
    var world: World
    var buf: Buffer
    var play: Play
    var m: Messenger
    var play_data: List[Int]
    var path: String

    fn __init__(out self, world: World):
        self.world = world
        self.play = Play(self.world)
        self.m = Messenger(self.world)
        self.play_data = List[Int](length=2, fill=0)
        self.path = String("resources/Shiverer.wav")
        self.buf = Buffer.load(self.path)

    fn __repr__(self) -> String:
        return String("MPlotExample")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        if self.m.notify_update(self.path, "load_sound"):
            self.buf = Buffer.load(self.path)

        trig = self.m.notify_update(self.play_data, "play_data")

        if trig:
            print("Playing slice: start=",self.play_data[0], ", num=", self.play_data[1])

        out = self.play.next(self.buf, 1.0, False, trig, self.play_data[0], self.play_data[1])

        return out
