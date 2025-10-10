"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_dsp.Filters import Lag

struct Default_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc
    var messenger: Messenger
    var freq: Float64
    var lag: Lag

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.messenger = Messenger(self.world_ptr)
        self.freq = 440.0
        self.lag = Lag(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> Float64:
        # get the frequency from the messenger, default to 440 Hz if not set
        # get_val can be called every sample, but is more efficient if called once per block
        if self.world_ptr[0].top_of_block:
            self.freq = self.messenger.get_val("freq", 440.0)

        return self.osc.next(self.freq) * 0.1


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