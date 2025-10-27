from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct TestMessengersRefactor(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var trig: TrigParam
    var f: Float64Param
    var gate: GateParam
    var lst: ListFloat64Param
    var txt: TextParam
    var printers: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)

        self.trig = TrigParam("trig_test", False)
        self.f = Float64Param("float_test", 0.0)
        self.gate = GateParam("gate_test", False)
        self.lst = ListFloat64Param("list_test", [0.0, 0.1, 0.2])
        self.txt = TextParam("text_test", ["default"])
        self.printers = List[Print](capacity=2)

        self.m.add_trig_param(self.trig)
        self.m.add_float64_param(self.f)
        self.m.add_gate_param(self.gate)
        self.m.add_list_float64_param(self.lst)
        self.m.add_text_param(self.txt)

        for i in range(2):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update()

        self.printers[0].next(self.f, "Float Value:",0.5)
        self.printers[1].next(self.gate, "Gate Value:",0.5)

        if self.trig:
            print("Trig Received! ********************************************")

        # if len(self.txt) > 0:
        #     for t in self.txt.strings:
        #         print("Text Received: ", t)
        
        # if len(self.lst) > 0:
        #     for l in self.lst.values:
        #         print("List Received: ", l)

        return SIMD[DType.float64, 2](0.0, 0.0)