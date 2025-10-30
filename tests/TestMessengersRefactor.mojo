from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct TestMessengersRefactor():
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var trig: TrigMsg
    var f: Float64
    var gate: GateMsg
    var float_list: List[Float64]
    var txt: TextMsg
    var printers: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)

        self.trig = TrigMsg()
        self.f = 0.0
        self.gate = GateMsg()
        self.float_list = { 10.0, 0.1, 0.2 } # really needs to be initialized this way (I think it's a Mojo thing)
        self.txt = TextMsg()
        self.printers = List[Print](capacity=2)

        self.m.add_param(self.trig,"test_trig")
        self.m.add_param(self.f,"freq")
        self.m.add_param(self.gate,"test_gate")
        self.m.add_param(self.float_list,"test_list")
        self.m.add_param(self.txt,"test_text")

        for i in range(2):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:    
        self.m.update()

        # self.printers[0].next(self.f, "Freq Value:",1)

        # if self.trig:
        #     print("Trig Received! ********************************************")

        # if len(self.txt) > 0:
        #     for t in self.txt.strings:
        #         print("Text Received: ", t)
        
        # if len(self.float_list) > 0:
        #     print("list len: ", len(self.float_list))
        #     for l in self.float_list:
        #         print("List: ", l)

        return SIMD[DType.float64, 2](0.0, 0.0)