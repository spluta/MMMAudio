from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *
from mmm_utils.Print import Print

struct Tone(Copyable, Movable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: Osc
    var freq: Float64
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: String):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        print("freq mem location Tone init: ", UnsafePointer(to=self.freq))
        self.m = Messenger(self.world_ptr,namespace)

        self.m.register(self.freq,"freq")

    fn next(mut self) -> Float64:    
        self.m.update()
        return self.osc.next(self.freq)

struct TestMessengersRefactor():
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var vol: Float64
    var tone0: Tone
    var tone1: Tone
    var printers: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)

        self.tone0 = Tone(self.world_ptr, "tone_0")
        self.tone1 = Tone(self.world_ptr, "tone_1")

        print("tone 0 freq mem location in TestMessengersRefactor init: ", UnsafePointer(to=self.tone0.freq))
        self.vol = -24.0
        self.printers = List[Print](capacity=2)

        self.m.register(self.vol,"vol")

        for i in range(2):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:    
        self.m.update()

        self.printers[0].next(self.tone0.freq, "tone 0 freq: ")
        self.printers[1].next(self.tone1.freq, "tone 1 freq: ")

        out = SIMD[DType.float64, 2](0.0, 0.0)
        out[0] = self.tone0.next()
        out[1] = self.tone1.next()

        return out * dbamp(self.vol)