from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from .synths.DelaySynth import DelaySynth

struct FeedbackDelays(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples

    var delay_synth: DelaySynth  # Instance of the Oscillator


    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        print("FeedbackDelays initialized with num_chans:", world_ptr[0].num_chans)

        self.delay_synth = DelaySynth(world_ptr)  # Initialize the DelaySynth with the world instance

        self.output = List[Float64]()  # Initialize output list

        for _ in range(self.world_ptr[0].num_chans):
            self.output.append(0.0)  # Initialize output list with zeros

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelays) -> List[Float64]:
        sample = self.delay_synth.next()

        zero(self.output)  # Clear the output list

        mix(self.output, sample)  # Mix the DelaySynth sample into the output

        return self.output  # Return the combined output sample