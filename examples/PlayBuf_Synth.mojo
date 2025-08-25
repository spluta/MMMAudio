from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Filters import Lag

from .synths.BufSynth import BufSynth

struct PlayBuf_Synth(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples

    var buf_synth: BufSynth  # Instance of the GrainSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        print("PlayBuf initialized with num_chans:", world_ptr[0].num_chans)

        self.buf_synth = BufSynth(world_ptr)  
        self.output = List[Float64]()  

        for _ in range(self.world_ptr[0].num_chans):
            self.output.append(0.0)  # Initialize output list with zeros

    fn __repr__(self) -> String:
        return String("PlayBuf")

    fn next(mut self: PlayBuf_Synth) -> List[Float64]:
        self.get_msgs()

        sample = self.buf_synth.next()

        zero(self.output)  # Clear the output list

        mix(self.output, sample) 

        return self.output  # Return the combined output sample

    fn get_msgs(mut self: Self):
        # calls to get_msg and get_midi return an Optional type
        # so you must get the value, then test the value to see if it exists, before using the value
        # get_msg returns a single list of values while get_midi returns a list of lists of values

        fader1 = self.world_ptr[0].get_msg("/fader1") # fader1 will be an Optional
        if fader1: # if fader1 is None, we do nothing
            self.buf_synth.playback_speed = linexp(fader1.value()[0], 0.0, 1.0, 0.25, 4.0)
        fader2 = self.world_ptr[0].get_msg("/fader2") # fader2 will be an Optional
        if fader2: # if fader2 is None, we do nothing
            freq = linexp(fader2.value()[0], 0.0, 1.0, 20.0, 20000.0)
            self.buf_synth.lpf_freq = freq