from mmm_audio import *

struct Tone(Movable,Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var osc: Osc
    var freq: Float64
    var m: Messenger
    var gate: Bool

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld], namespace: String):
        self.world = world
        self.osc = Osc(self.world)
        self.freq = 440.0
        self.m = Messenger(self.world,namespace)
        self.gate = False

    fn next(mut self) -> Float64:

        if self.m.notify_update(self.freq,"freq"):
            print("Tone freq updated to ", self.freq)

        if self.m.notify_update(self.gate,"gate"):
            print("Tone gate updated to ", self.gate)

        sig = self.osc.next(self.freq) if self.gate else 0.0

        return sig

struct MessengerExample(Copyable, Movable):
    var world: LegacyUnsafePointer[MMMWorld]
    var m: Messenger
    var tones: List[Tone]
    
    var bool: Bool
    var bools: List[Bool]
    var float: Float64
    var floats: List[Float64]
    var int: Int64
    var ints: List[Int64]
    var string: String
    var strings: List[String]

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.m = Messenger(self.world)

        self.tones = List[Tone]()
        for i in range(2):
            self.tones.append(Tone(self.world, "tone_" + String(i)))

        self.bool = False
        self.bools = List[Bool](False, False)
        self.float = 0.0
        self.floats = List[Float64](0.0, 0.0)
        self.int = 0
        self.ints = List[Int64](0, 0)
        self.string = ""
        self.strings = List[String]("", "")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        
        if self.m.notify_update(self.bool,"bool"):
            print("Bool value is now: " + String(self.bool))

        if self.m.notify_update(self.float,"float"):
            print("Float value is now: " + String(self.float))

        if self.m.notify_update(self.floats,"floats"):
            print("Updated floats to ")
            for f in self.floats:
                print("  ", f)

        if self.m.notify_update(self.int,"int"):
            print("Updated int to ", self.int)

        if self.m.notify_update(self.ints,"ints"):
            print("Updated ints to:", end="")
            for i in self.ints:
                print("  ", i, end="")
            print("")

        if self.m.notify_update(self.string,"string"):
            print("Updated string to ", self.string)

        if self.m.notify_update(self.strings,"strings"):
            print("Updated strings to ")
            for s in self.strings:
                print("  ", s)

        if self.m.notify_trig("trig"):
            print("Received trig")

        out = SIMD[DType.float64, 2](0.0, 0.0)
        for i in range(2):
            out[i] = self.tones[i].next()

        return out * dbamp(-20.0)
