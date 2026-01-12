
from mmm_audio import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestOscOversampling(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
    var osc: Osc
    var osc1: Osc[1,1,1]
    var osc2: Osc[1,1,2]
    var osc3: Osc[1,1,3]
    var osc4: Osc[1,1,4]
    var which: Float64
    var messenger: Messenger

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.osc = Osc(world)
        self.osc1 = Osc[1,1,1](world)
        self.osc2 = Osc[1,1,2](world)
        self.osc3 = Osc[1,1,3](world)
        self.osc4 = Osc[1,1,4](world)
        self.which = 0.0
        self.messenger = Messenger(world)

    fn next(mut self) -> Float64:
        self.messenger.update(self.which, "which")

        sample = select(self.which, [
            self.osc.next(self.world[].mouse_y * 200.0 + 20.0),
            self.osc1.next(self.world[].mouse_y * 200.0 + 20.0)[0],
            self.osc2.next(self.world[].mouse_y * 200.0 + 20.0)[0],
            self.osc3.next(self.world[].mouse_y * 200.0 + 20.0)[0],
            self.osc4.next(self.world[].mouse_y * 200.0 + 20.0)[0],
        ])

        return sample * 0.2
