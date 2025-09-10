from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from mmm_dsp.Pan import PanAz

struct PanAz_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc
    var freq: Float64

    var pan_osc: Osc
    var pan_az: PanAz

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0

        self.pan_osc = Osc(self.world_ptr)
        self.pan_az = PanAz()

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 8]:
        
        self.get_msgs()

        panned = self.pan_az.next[8](self.osc.next(self.freq), self.pan_osc.next(0.1) * 0.5 + 0.5, 5) * 0.1

        return panned

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("osc_freq")
        if msg:
            self.freq = msg.value()[0]

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct Pan_Az(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: PanAz_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = PanAz_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("PanAz")

    fn next(mut self) -> List[Float64]:

        sample = self.synth.next()  # Get the next sample from the synth

        return [sample[0],sample[1],sample[2],sample[3],sample[4]]  # Return the combined output samples