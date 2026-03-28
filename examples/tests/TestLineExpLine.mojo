
from mmm_audio import *

comptime num: Int = 1

struct TestLineExpLine[](Movable, Copyable):
    var world: World
    var osc: Osc[num]
    var osc2: Osc[num]
    var osc3: Osc[num]
    var line_vals: List[Float64]
    var m: Messenger
    var line: Line[num]
    var expline: Line[num, 1]
    var curveline: Line[num, 2]
    var which: Int

    fn __init__(out self, world: World):
        self.world = world
        self.osc = Osc[num](self.world)
        self.osc2 = Osc[num](self.world)
        self.osc3 = Osc[num](self.world)
        self.line_vals = [440.0, 880.0, 1.0]
        self.m = Messenger(self.world)
        self.line = Line[num](self.world)
        self.which = 0
        self.expline = Line[num, 1](self.world)
        self.curveline = Line[num, 2](self.world)

    fn next(mut self) -> MFloat[2]:
        trig = self.m.notify_update(self.line_vals, "line_vals")
        trig2 = MBool[num](fill = trig)
        self.m.update(self.which, "which")
        
        line = self.line.next(self.line_vals[0], self.line_vals[1], self.line_vals[2], trig2)
        expline = self.expline.next(self.line_vals[0], self.line_vals[1], self.line_vals[2], trig2)
        curveline = self.curveline.next(self.line_vals[0], self.line_vals[1], self.line_vals[2], trig2)

        line, expline, curveline = self.osc.next(line), self.osc2.next(expline), self.osc3.next(curveline)

        return select(self.which, MFloat[2](line), MFloat[2](expline), MFloat[2](curveline), splay(line, expline, curveline, world=self.world) ) * 0.1