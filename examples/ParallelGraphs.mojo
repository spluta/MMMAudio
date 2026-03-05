from mmm_audio import *

struct ParallelGraphs(Representable, Movable, Copyable):
    var world: World  
    var osc: Osc[1,Interp.sinc,1]
    var filt: SVF[1]
    var messenger: Messenger
    var freq: Float64
    var pan: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.osc = Osc[1,Interp.sinc,1](self.world)
        self.filt = SVF[1](self.world)
        self.messenger = Messenger(self.world)
        self.freq = 440.0
        self.pan = -1.0

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> MFloat[2]:
        self.messenger.update(self.freq,"freq")
        self.messenger.update(self.pan,"pan")

        osc = self.osc.next(self.freq, osc_type=OscType.saw) 
        osc = self.filt.next[filter_type=SVFModes.lowpass](osc, 2000.0, 1.0)
        osc2 = pan2(osc, self.pan)

        return osc2 * 0.3