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
    var printer: Print

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: String):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        self.m = Messenger(self.world_ptr, namespace)
        self.printer = Print(self.world_ptr)

        self.m.add_param(self.freq,"freq")

    fn next(mut self) -> Float64:    
        self.m.update()
        self.printer.next(self.freq, "Freq Value:", 1)
        return self.osc.next(self.freq)

struct TestMessengersRefactor():
    var world_ptr: UnsafePointer[MMMWorld]
    var m: Messenger
    var trig: TrigMsg
    var vol: Float64
    var gate: GateMsg
    var float_list: List[Float64]
    var txt: TextMsg
    var tones: InlineArray[Tone, 2]
    var printers: List[Print]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.m = Messenger(world_ptr)
        self.tones = InlineArray[Tone, 2](uninitialized=True)
        for i in range(2):
            self.tones[i] = Tone(world_ptr, "tone_" + String(i))

        self.trig = TrigMsg()
        self.vol = -24.0
        self.gate = GateMsg()
        self.float_list = { 10.0, 0.1, 0.2 } # really needs to be initialized this way (I think it's a Mojo thing)
        self.txt = TextMsg()
        self.printers = List[Print](capacity=2)

        self.m.add_param(self.trig,"test_trig")
        self.m.add_param(self.vol,"vol")
        self.m.add_param(self.gate,"test_gate")
        self.m.add_param(self.float_list,"test_list")
        self.m.add_param(self.txt,"test_text")

        for i in range(2):
            self.printers.append(Print(world_ptr))

    fn next(mut self) -> SIMD[DType.float64, 2]:    
        self.m.update()

        self.printers[0].next(self.vol, "Volume (dB):", 1)
        self.printers[1].next(self.gate, "Gate State:", 1)
        self.printers[2].next(self.float_list.__len__(), "Float List Length:", 1)
        self.printers[3].next(self.txt.__repr__(), "Text Message:", 1)

        if self.trig:
            for i in range(2):
                self.printers[i].next(self.tones[i].freq, "Tone " + String(i) + " Freq on Trigger:", 1)

        out = SIMD[DType.float64, 2](0.0, 0.0)
        for i in range(2):
            out[i] = self.tones[i].next() 

        return out * dbamp(self.vol)