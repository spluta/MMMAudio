"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import *
from mmm_dsp.Filters import SVF

struct Default_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc[1,2,1]
    var filt: SVF
    var messenger: Messenger
    var freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc[1,2,1](self.world_ptr)
        self.filt = SVF(self.world_ptr)
        self.messenger = Messenger(self.world_ptr)
        self.freq = 440.0

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> Float64:
        self.messenger.update(self.freq,"freq")

        osc = self.osc.next(self.freq, osc_type=OscType.bandlimited_saw) 
        # osc = self.filt.lpf(osc, 1000, 1.0)

        return osc


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct DefaultGraph(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Default_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Default_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default_Graph")

    fn next(mut self) -> SIMD[DType.float64, 1]:

        return self.synth.next()  # Get the next sample from the synth