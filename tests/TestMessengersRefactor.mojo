from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print
from mmm_utils.RisingBoolDetector import RisingBoolDetector

struct Tone(Movable,Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var freq: Float64
    var m: Messenger
    var test_gate: Bool
    var test_trig: Trig
    var float_list: List[Float64]
    var rising_edge: RisingBoolDetector
    var Ints: List[Int64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: String):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        print("freq mem location Tone init: ", UnsafePointer(to=self.freq))
        self.m = Messenger(self.world_ptr,namespace)
        self.test_gate = False
        self.test_trig = Trig(False)
        self.float_list = List[Float64]()
        self.rising_edge = RisingBoolDetector()
        self.Ints = List[Int64]()

    fn next(mut self) -> Float64:
        self.m.update(self.Ints, "test_ints")
        if self.m.check_ints("test_ints"):
            print("Received Int list via Messenger:")
            for i in range(len(self.Ints)):
                print("  ", self.Ints[i])

        if self.m.check_floats("test_floats"):
            float_list = List[Float64]()
            self.m.update(float_list, "test_floats")
            print("Received float list via Messenger:")
            for i in range(len(float_list)):
                print("  ", float_list[i])

        if self.m.check_texts("file_name"):
            file_name = String("")
            self.m.update(file_name, "file_name")
            print("got a file_name", file_name)
        
        if self.m.check_texts("file_name"):
            file_name2 = List[String]()
            self.m.update(file_name2, "file_name")
            print("got multiple file_names:")
            for i in range(len(file_name2)):
                print("  ", file_name2[i])

        self.m.update(self.freq, "freq")
        
        self.m.update(self.test_gate, "test_gate")
        if self.rising_edge.next(self.test_gate):
            print("Tone test_gate set to True!")

        if self.m.check_gate("test_gate"):
            print("Gate is there!")

        self.m.update(self.test_trig, "test_trig")
        if self.test_trig:
            print("Tone received test_trig!")

        if self.m.check_trig("test_trig"):
            print("Trig is there!")

        if self.m.check_trigs("test_trigs"):
            trig_list = List[Trig]()
            self.m.update(trig_list, "test_trigs")
            print("Received trig list via Messenger:")
            for i in range(len(trig_list)):
                print("  ", trig_list[i])

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
    var bools: List[Bool]

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

        self.bools = List[Bool](False,False,False,False)

    fn next(mut self) -> SIMD[DType.float64, 2]:    
        self.m.update(self.vol,"vol")
        self.m.update(self.test_int,"test_int")

        if self.m.check_floats("test_floats"):
            float_list = List[Float64]()
            self.m.update(float_list, "test_floats")
            for i in range(min(len(float_list), len(self.tone_list))):
                self.tone_list[i].freq = float_list[i]

        if self.m.check_bools("test_bools"):
            gate_list = List[Bool]()
            self.m.update(gate_list,"test_bools")
            for i in range(len(gate_list)):
                print(gate_list[i], end=" ")
            print("")

        if self.m.check_texts("text_test"):
            print("got text message!")
            txt = List[String]()
            self.m.update(txt,"text_test")
            for i in range(len(txt)):
                print("TextMsg txt ",i,": ",txt[i])

        if self.test_int > 0:
            self.printers[2].next(self.test_int,"TestMessengersRefactor test_int:")

        self.m.update(self.trig, "test_trig")
        if self.trig:
            freq = random_float64(200.0, 800.0)
            for i in range(len(self.tone_list)):
                self.tone_list[i].freq = freq + i * 3.0
            print("Trig received!")

        out = SIMD[DType.float64, 2](0.0, 0.0)
        out[0] = self.tone_list[0].next()
        out[1] = self.tone_list[1].next()

        return out * dbamp(self.vol)
