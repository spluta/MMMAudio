from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from random import random_float64
from mmm_dsp.Pan import Pan2
from mmm_dsp.OscBuffers import OscBuffers

# THE SYNTH

# The synth here is not yet the "graph" that MMMAudio will 
# call upon to make sound with. StereoOscSynth is a struct that
# defines some DSP behavior that can be called upon by 
# the ManyOscillators graph below.

struct StereoOscSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] # pointer to the MMMWorld
    var oscs: Osc[2] # two oscillators
    var osc_freqs: SIMD[DType.float64, 2] # frequencies for the two oscillators
    var pan2: Pan2 # panning processor
    var pan2_osc: Osc # LFO for panning
    var pan2_freq: Float64 # frequency for the panning LFO
    var vol_osc: Osc # LFO for volume
    var vol_osc_freq: Float64 # frequency for the volume LFO
    var temp: Float64 # temporary variable for processing

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], center_freq: Float64):
        self.world_ptr = world_ptr

        # create two oscillators. The [2] here is *kind of* like an array
        # with two elements, but the more accurate way to look at it is a
        # SIMD operation with a width of 2. For more info on MMMAudio's SIMD 
        # support, see: https://spluta.github.io/MMMAudio/api/ 
        # Just FYI, it's not 2 because this is a stereo synth, it's 2 to
        # create some nice beating patterns. The output is stereo because later
        # the Pan2 processor positions the summed oscillators in the stereo field.
        self.oscs = Osc[2](world_ptr)

        self.pan2 = Pan2(world_ptr)
        self.pan2_osc = Osc(world_ptr)
        self.pan2_freq = random_float64(0.03, 0.1)

        self.vol_osc = Osc(world_ptr)
        self.vol_osc_freq = random_float64(0.05, 0.2)
        self.osc_freqs = SIMD[DType.float64, 2](
            center_freq + random_float64(1.0, 5.0),
            center_freq - random_float64(1.0, 5.0)
        )
        self.temp = 0.0

    fn __repr__(self) -> String:
        return String("StereoOscSynth")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        # calling .next on both oscillators gets both of their next samples
        # at the same time as a SIMD operation
        # [TODO] it seems that temp magically (multi-channel-expansion-ally) becomes a SIMD variable here. I think it would be good to be explained what's happening.
        temp = self.oscs.next(self.osc_freqs, interp = 0, os_index = 0) 

        # modulate the volume with a slow LFO
        # [TODO] is this applying the LFO in a multi-channel-expansion way? That feels "non-SIMD"-esque? In any case, it should be explained.
        temp = temp * (self.vol_osc.next(self.vol_osc_freq) * 0.01 + 0.01)
        temp2 = temp[0] + temp[1]

        self.world_ptr[0].print(self.osc_freqs, "freqs", freq=1.0)

        pan2_loc = self.pan2_osc.next(self.pan2_freq)  # Get pan position

        return self.pan2.next(temp2, pan2_loc)  # Pan the temp signal

# THE GRAPH
# This graph is what MMMAudio will call upon to make sound with (because
# it is the struct that has the same name as this).

struct ManyOscillators(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var osc_synths: List[StereoOscSynth]  # Instances of the Oscillator
    var num_pairs: Int

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        # initialize the list of oscillator pairs
        self.osc_synths = List[StereoOscSynth]()
        # add 10 pairs to the list
        self.num_pairs = 10
        for _ in range(self.num_pairs):
            self.osc_synths.append(StereoOscSynth(self.world_ptr, random_exp_float64(100.0, 1000.0)))  

    fn __repr__(self) -> String:
        return String("ManyOscillators")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()

        # sum all the stereo outs from the N oscillator pairs
        sum = SIMD[DType.float64, 2](0.0, 0.0)
        for i in range(self.num_pairs):
            sum += self.osc_synths[i].next()

        return sum

    fn get_msgs(mut self):
        # get any messages sent from Python to the Mojo program

        # num here will be Type "None" if there is no message called "set_num_pairs"
        # if there is a message called "set_num_pairs", num will the contents of the message
        # [TODO]: is the type and data structure known? I know lower we index in but I think
        # it would be valuable to explain what to expect here.
        num = self.world_ptr[0].get_msg("set_num_pairs")

        # [TODO]: PICK UP HERE
        if num:
            if num.value()[0] != self.num_pairs:
                print("Changing number of osc pairs to:", Int(num.value()[0]))
                # adjust the list of osc synths
                if Int(num.value()[0]) > self.num_pairs:
                    # add more
                    for _ in range(Int(num.value()[0]) - self.num_pairs):
                        self.osc_synths.append(StereoOscSynth(self.world_ptr, random_exp_float64(100.0, 1000.0)))  
                else:
                    # remove some
                    for _ in range(self.num_pairs - Int(num.value()[0])):
                        _ = self.osc_synths.pop()
            self.num_pairs = Int(num.value()[0])