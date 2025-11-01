from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct Tone(Messagable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var freq: Float64
    var test_list: List[Float64]
    var m: Messenger
    var start: Bool

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: String):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        print("freq mem location Tone init: ", UnsafePointer(to=self.freq))
        self.m = Messenger(self.world_ptr,namespace)
        self.test_list = List[Float64](capacity=4)
        self.start = True

    fn register_messages(mut self):
        self.m.register(self.freq,"freq")
        self.m.register(self.test_list,"test_list")

    fn next(mut self) -> Float64:
        self.m.update()
        return self.osc.next(self.freq)

struct TestMessengersRefactor():
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var vol: Float64
    var tone_list: List[Tone]
    var printers: List[Print]
    var test_int: Int64
    var txt: TextMsg
    var trig: TrigMsg

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)
        self.test_int = 0
        self.txt = TextMsg(List[String]("hello","there","general","kenobi"))
        self.trig = TrigMsg(True)

        self.tone_list = List[Tone](capacity=2)
        for i in range(2):
            self.tone_list.append(Tone(self.world_ptr, "tone_"+String(i)))
            self.tone_list[i].register_messages()

        print("tone 0 freq mem location in TestMessengersRefactor init: ", UnsafePointer(to=self.tone_list[0].freq))
        self.vol = -24.0
        self.printers = List[Print](capacity=4)

        self.m.register(self.vol,"vol")
        self.m.register(self.test_int,"test_int")
        self.m.register(self.txt,"text_test")
        self.m.register(self.trig,"trig_test")

        for i in range(4):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:    
        self.m.update()

        if len(self.txt) > 0:
            self.printers[0].next(self.txt[0],"TextMsg txt 0:")

        if len(self.txt) > 1:
            self.printers[1].next(self.txt[1],"TextMsg txt 1:")

        if self.test_int > 0:
            self.printers[2].next(self.test_int,"TestMessengersRefactor test_int:")

        self.printers[3].next(self.vol,"TestMessengersRefactor vol:")

        if self.trig:
            print("TrigMsg received trig!")

        out = SIMD[DType.float64, 2](0.0, 0.0)
        out[0] = self.tone_list[0].next()
        out[1] = self.tone_list[1].next()

        return out * dbamp(self.vol)