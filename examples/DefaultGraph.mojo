from mmm_audio import *

struct Default_Synth(Representable, Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]  
    var osc: Osc[1,Interp.sinc,1]
    var filt: SVF
    var messenger: Messenger
    var freq: Float64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.osc = Osc[1,Interp.sinc,1](self.world)
        self.filt = SVF(self.world)
        self.messenger = Messenger(self.world)
        self.freq = 440.0

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> Float64:
        self.messenger.update(self.freq,"freq")

        osc = self.osc.next(self.freq, osc_type=OscType.bandlimited_saw) 
        osc = self.filt.next[filter_type=SVFModes.lowpass](osc, 2000.0, 1.0)

        return osc * 0.3


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct DefaultGraph(Representable, Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var synth: Default_Synth

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.synth = Default_Synth(self.world)

    fn __repr__(self) -> String:
        return String("Default_Graph")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        return self.synth.next()  # Get the next sample from the synth