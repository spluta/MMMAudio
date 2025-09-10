from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc

struct Record_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  

    var outs: List[Float64]
    var osc: Osc
    var freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 375.0
        self.outs = List[Float64]()
        for _ in range(12):
            self.outs.append(0.0)

    fn __repr__(self) -> String:
        return String("Record_Synth")

    fn next(mut self) -> List[Float64]:
        self.get_msgs()

        smaller  = min(len(self.outs), len(self.world_ptr[0].sound_in))
        for i in range(smaller):
            self.outs[i] = self.world_ptr[0].sound_in[i]

        return self.outs

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("print_inputs")
        if msg:
            for i in range(self.world_ptr[0].num_in_chans):
                print("input[", i, "] =", self.world_ptr[0].sound_in[i])

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct Record(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]
    var synth: Record_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.output = List[Float64]()
        for _ in range(12):
            self.output.append(0.0)  # Initialize output list with zeros
        self.synth = Record_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Record")

    fn next(mut self) -> List[Float64]:
        zero(self.output) # Clear the output buffer

        sample = self.synth.next()  # Get the next sample from the synth

        mix(self.output, sample)  # mix any synth outputs into the output buffer

        return self.output  # Return the combined output samples