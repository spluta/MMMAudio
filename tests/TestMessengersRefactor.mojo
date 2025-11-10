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
    var gate: Bool

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: String):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        self.m = Messenger(self.world_ptr,namespace)
        self.gate = False

    fn next(mut self) -> Float64:

        self.m.update(self.freq, "freq")
        self.m.update(self.gate, "gate")

        if self.m.has_new_float("freq"):
            print("Tone freq updated to ", self.freq)
        
        if self.m.has_new_bool("gate"):
            print("Tone gate updated to ", self.gate)

        sig = self.osc.next(self.freq) if self.gate else 0.0

        return sig

struct TestMessengersRefactor():
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var tones: List[Tone]
    
    var bool: Bool
    var bools: List[Bool]
    var float: Float64
    var floats: List[Float64]
    var int: Int64
    var ints: List[Int64]
    var trig: Trig
    var trigs: List[Trig]
    var string: String
    var strings: List[String]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)

        self.tones = List[Tone]()
        for i in range(2):
            self.tones.append(Tone(world_ptr, "tone_" + String(i)))

        self.bool = False
        self.bools = List[Bool](False, False)
        self.float = 0.0
        self.floats = List[Float64](0.0, 0.0)
        self.int = 0
        self.ints = List[Int64](0, 0)
        self.trig = Trig()
        self.trigs = List[Trig](Trig(), Trig())
        self.string = ""
        self.strings = List[String]("", "")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        if self.m.has_new_bool("bool"):
            self.m.update(self.bool, "bool")
            print("Updated bool to ", self.bool)

        if self.m.has_new_bools("bools"):
            self.m.update(self.bools, "bools")
            print("Updated bools to ")
            for b in self.bools:
                print("  ", b)

        if self.m.has_new_float("float"):
            self.m.update(self.float, "float")
            print("Updated float to ", self.float)

        if self.m.has_new_floats("floats"):
            self.m.update(self.floats, "floats")
            print("Updated floats to ")
            for f in self.floats:
                print("  ", f)

        if self.m.has_new_int("int"):
            self.m.update(self.int, "int")
            print("Updated int to ", self.int)

        if self.m.has_new_ints("ints"):
            self.m.update(self.ints, "ints")
            print("Updated ints to ")
            for i in self.ints:
                print("  ", i)

        if self.m.has_new_trig("trig"):
            self.m.update(self.trig, "trig")
            print("Received trig")

        self.m.update(self.trigs, "trigs")
        for i in range(len(self.trigs)):
            if self.trigs[i]:
                print("Received trig ", i)

        if self.m.has_new_string("string"):
            self.m.update(self.string, "string")
            print("Updated string to ", self.string)

        if self.m.has_new_strings("strings"):
            self.m.update(self.strings, "strings")
            print("Updated strings to ")
            for s in self.strings:
                print("  ", s)

        out = SIMD[DType.float64, 2](0.0, 0.0)
        for i in range(2):
            out[i] = self.tones[i].next()

        return out * dbamp(-20)
