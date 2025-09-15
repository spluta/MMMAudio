from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Phasor, Osc
from mmm_dsp.Pan import PanAz

struct PanAz_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc
    var freq: Float64

    var pan_osc: Phasor
    var pan_az: PanAz

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = 440.0

        self.pan_osc = Phasor(self.world_ptr)
        self.pan_az = PanAz(self.world_ptr)

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 8]:
        
        self.get_msgs()

        # PanAz needs to be given a SIMD size that is a power of 2, in this case [8], but the speaker size can be anything smaller than that
        panned = self.pan_az.next[8](self.osc.next(self.freq, osc_type=2), self.pan_osc.next(0.1), 2, 2) * 0.1

        return panned

    fn get_msgs(mut self: Self):
        # Get messages from the world
        msg = self.world_ptr[0].get_msg("osc_freq")
        if msg:
            self.freq = msg.value()[0]

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct Pan_Az(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: PanAz_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = PanAz_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("PanAz")

    fn next(mut self) -> SIMD[DType.float64, 8]:

        sample = self.synth.next()  # Get the next sample from the synth

        # the output will pan to the number of channels available 
        # if there are fewer than 5 channels, only those channels will be output
        return sample  # Return the combined output samples