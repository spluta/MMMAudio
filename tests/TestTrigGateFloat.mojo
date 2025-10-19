from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct TestTrigGateFloat(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var trig: Bool
    var f: Float64
    var gate: Bool
    var printers: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)
        self.trig = False
        self.f = 0.0
        self.gate = False
        self.printers = List[Print](capacity=2)
        for i in range(2):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:

        fl = self.m.get_float("float_test", 1.0)
        gt = self.m.get_gate("gate_test", False)
        tg = self.m.get_trig("trig_test")

        self.printers[0].next(fl, "Float Value:")
        self.printers[1].next(gt, "Gate Value:")

        if tg:
            print("Trig Received! ********************************************")

        return SIMD[DType.float64, 2](0.0, 0.0)