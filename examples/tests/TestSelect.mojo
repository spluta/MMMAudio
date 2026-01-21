
from mmm_audio import *

struct TestSelect(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var messenger: Messenger
    var vs: List[Float64]
    var printers: List[Print]
    var which: Float64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.messenger = Messenger(self.world)
        self.vs = List[Float64](capacity=8)
        self.printers = List[Print](capacity=2)
        self.which = 0.0
        for i in range(8):
            self.vs.append(i * 100)

        self.printers[0] = Print(self.world)
        self.printers[1] = Print(self.world)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.vs, "vs")
        self.messenger.update(self.which,"which")

        val = select(self.which, self.vs)
        self.printers[0].next(val, "selected value in self.vs: ")

        val2 = select(self.which,[11.1,12.2,13.3,14.4,15.5,16.6,17.7,18.8])
        self.printers[1].next(val2, "selected value in [11..18]: ")

        return SIMD[DType.float64, 2](0.0, 0.0)