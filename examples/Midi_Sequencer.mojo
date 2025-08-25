from mmm_src.MMMWorld import MMMWorld

from .synths.TrigSynth import TrigSynth

from mmm_utils.functions import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import *
from mmm_dsp.Env import Env
from collections.dict import DictEntry


from mmm_src.MMMTraits import *

struct Midi_Sequencer(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples

    var trig_synth: TrigSynth  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.output = List[Float64]()  # Initialize output list
        for _ in range(self.world_ptr[0].num_chans):
            self.output.append(0.0)  # Initialize output list with zeros

        self.trig_synth = TrigSynth(world_ptr)  # Initialize the TrigSynth with the world instance

    fn __repr__(self) -> String:
        return String("Midi_Sequencer")

    fn next(mut self: Midi_Sequencer) -> List[Float64]:
        sample = self.trig_synth.next()

        zero(self.output)  # Clear the output list
        mix(self.output, sample)  # Mix the BufSynth sample into the output

        return self.output  # Return the combined output sample

