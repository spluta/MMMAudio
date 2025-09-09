from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc

struct Default_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc
    var freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> Float64:
        
        self.get_msgs()
        return self.osc.next(self.freq) * 0.1

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("osc_freq")
        if msg:
            self.freq = msg.value()[0]

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct Default_Graph(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]
    var synth: Default_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.output = List[Float64](0.0, 0.0)
        self.synth = Default_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> List[Float64]:
        zero(self.output) # Clear the output buffer

        sample = self.synth.next()  # Get the next sample from the synth

        mix(self.output, sample)  # mix any synth outputs into the output buffer

        return self.output  # Return the combined output samples