from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Phasor, Osc
from mmm_dsp.Pan import PanAz

struct PanAz_Synth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var osc: Osc
    var freq: Messenger

    var pan_osc: Phasor
    var pan_az: PanAz # set the number of speakers in the constructor
    var num_speakers: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = Osc(self.world_ptr)
        self.freq = Messenger(self.world_ptr, 440.0)

        self.pan_osc = Phasor(self.world_ptr)
        self.pan_az = PanAz(self.world_ptr)
        self.num_speakers = Messenger(self.world_ptr, 2)  # default to 2 speakers

    fn __repr__(self) -> String:
        return String("Default")

    fn next(mut self) -> SIMD[DType.float64, 8]:
        self.freq.get_msg("freq")
        self.num_speakers.get_msg("num_speakers")

        # PanAz needs to be given a SIMD size that is a power of 2, in this case [8], but the speaker size can be anything smaller than that
        panned = self.pan_az.next[8](self.osc.next(self.freq.value, osc_type=2), self.pan_osc.next(0.1), self.num_speakers.int_value) * 0.1

        return panned


# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct PanAzExample(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synth: PanAz_Synth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.synth = PanAz_Synth(self.world_ptr)

    fn __repr__(self) -> String:
        return String("PanAzExample")

    fn next(mut self) -> SIMD[DType.float64, 8]:

        sample = self.synth.next()  # Get the next sample from the synth

        # the output will pan to the number of channels available 
        # if there are fewer than 5 channels, only those channels will be output
        return sample  # Return the combined output samples