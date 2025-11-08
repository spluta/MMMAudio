from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct Tone(Movable,Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var freq: Float64
    var m: Messenger
    var file_name: List[String]
    var test_bool: Bool
    var float_list: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: String):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        print("freq mem location Tone init: ", UnsafePointer(to=self.freq))
        self.m = Messenger(self.world_ptr,namespace)
        self.file_name = List[String]()
        self.test_bool = False
        self.float_list = List[Float64]()


    fn next(mut self) -> Float64:

        # got_it = self.m.update(self.float_list, "test_list")
        # if got_it:
        #     print("Received float list via Messenger:")
        #     for i in range(len(self.float_list)):
        #         print("  ", self.float_list[i])

        if self.m.check_floats("test_list"):
            float_list: List[Float64] = List[Float64]()
            self.m.update(float_list, "test_list")
            print("Received float list via Messenger:")
            for i in range(len(float_list)):
                print("  ", float_list[i])

        received_filename = self.m.update(self.file_name, "file_name")
        self.m.update(self.test_bool, "test_bool")
        self.m.update(self.freq, "freq")

        if received_filename:
            for i in range(len(self.file_name)):
                print(self.file_name[i])
        if self.test_bool:
            print("Tone received test_bool True!")

        # self.world_ptr[0].print(self.freq)
        return self.osc.next(self.freq)

struct TestMessengersRefactor():
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var vol: Float64
    var tone_list: List[Tone]
    var printers: List[Print]
    var test_int: Int64
    var txt: List[String]
    var trig: Trig

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)
        self.test_int = 0
        self.txt = List[String]("hello","there","general","kenobi")
        self.trig = Trig(False)

        self.tone_list = List[Tone](capacity=2)
        for i in range(2):
            self.tone_list.append(Tone(self.world_ptr, "tone_"+String(i)))

        print("tone 0 freq mem location in TestMessengersRefactor init: ", UnsafePointer(to=self.tone_list[0].freq))
        self.vol = -24.0
        self.printers = List[Print](capacity=4)

        for i in range(4):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:    
        self.m.update(self.vol,"vol")
        self.m.update(self.test_int,"test_int")
        got_text = self.m.update(self.txt,"text_test")
        self.m.update(self.trig, "trig_test")

        if got_text:
            for i in range(len(self.txt)):
                print("TextMsg txt ",i,": ",self.txt[i])

        if self.test_int > 0:
            self.printers[2].next(self.test_int,"TestMessengersRefactor test_int:")

        if self.trig:
            print("TrigMsg received trig!")

        out = SIMD[DType.float64, 2](0.0, 0.0)
        out[0] = self.tone_list[0].next()
        out[1] = self.tone_list[1].next()

        return out * dbamp(self.vol)
