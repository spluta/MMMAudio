"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_dsp.Filters import Lag

struct Default_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc
    var freq: Float64
    var lag: Lag

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0
        self.lag = Lag(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> Float64:
        
        self.get_msgs()
        freq = self.lag.next(self.freq, 3)
        print(freq[0], self.freq)
        return self.osc.next(freq[0]) * 0.1

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("osc_freq")
        if msg:
            self.freq = msg.value()[0]

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct Default_Graph(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: Default_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = Default_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default_Graph")

    fn next(mut self) -> SIMD[DType.float64, 1]:

        return self.synth.next()  # Get the next sample from the synth