from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import *
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from random import random_float64
from mmm_dsp.Pan import Pan2
from mmm_dsp.OscBuffers import OscBuffers

# THE SYNTH


# The synth here, called StereoBeatingSines, is not yet the "graph" that MMMAudio will 
# call upon to make sound with. StereoBeatingSines is a struct that
# defines some DSP behavior that can be called upon by 
# the ManyOscillators graph below.

struct StereoBeatingSines(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] # pointer to the MMMWorld
    var oscs: Osc[2]  # An Osc instance with two internal Oscs
    var osc_freqs: SIMD[DType.float64, 2] # frequencies for the two oscillators
    var pan2: Pan2 # panning processor
    var pan2_osc: Osc # LFO for panning
    var pan2_freq: Float64 # frequency for the panning LFO
    var vol_osc: Osc # LFO for volume
    var vol_osc_freq: Float64 # frequency for the volume LFO

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], center_freq: Float64):
        self.world_ptr = world_ptr

        # create two oscillators. The [2] here is *kind of* like an array
        # with two elements, but the more accurate way to look at it is a
        # SIMD operation with a width of 2. For more info on MMMAudio's SIMD 
        # support, see: https://spluta.github.io/MMMAudio/api/ 
        # Just FYI, it's not 2 because this is a stereo synth, it's 2 to
        # create some nice beating patterns. The output is stereo because later
        # the Pan2 processor positions the summed oscillators in the stereo field

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

    fn __repr__(self) -> String:
        return String("StereoBeatingSines")

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        # calling .next on both oscillators gets both of their next samples
        # at the same time as a SIMD operation
        # [TODO] it seems that temp magically (multi-channel-expansion-ally) becomes a SIMD variable here. I think it would be good to be explained what's happening.
        temp = self.oscs.next(self.osc_freqs) 

        # modulate the volume with a slow LFO
        # [TODO] is this applying the LFO in a multi-channel-expansion way? That feels "non-SIMD"-esque? In any case, it should be explained.
        temp = temp * (self.vol_osc.next(self.vol_osc_freq) * 0.01 + 0.01)
        temp2 = temp[0] + temp[1]

        pan2_loc = self.pan2_osc.next(self.pan2_freq)  # Get pan position

        return self.pan2.next(temp2, pan2_loc)  # Pan the temp signal

# THE GRAPH
# This graph is what MMMAudio will call upon to make sound with (because
# it is the struct that has the same name as this).

struct ManyOscillators(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var synths: List[StereoBeatingSines]  # Instances of the StereoBeatingSines synth
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        # initialize the list of synths
        self.synths = List[StereoBeatingSines]()

        self.messenger = Messenger(self.world_ptr)

        # add 10 pairs to the list
        for _ in range(10):
            self.synths.append(StereoBeatingSines(self.world_ptr, random_exp_float64(100.0, 1000.0)))

    fn __repr__(self) -> String:
        return String("ManyOscillators")

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()

        # sum all the stereo outs from the N synths
        sum = SIMD[DType.float64, 2](0.0, 0.0)
        for i in range(len(self.synths)):
            sum += self.synths[i].next()

        return sum

    fn get_msgs(mut self):
        # get any messages sent from Python to the Mojo program

        # if there is a message called "set_num_pairs", num will either return the value sent with "set_num_pairs" or if no value has been sent, it will return the default value of 10
        if self.world_ptr[0].block_state == 0:
            num = self.messenger.val("set_num_pairs", 10)

            if num != len(self.synths):
                print("Changing number of synths to:", Int(num))
                # adjust the list of synths
                if Int(num) > len(self.synths):
                    # add more
                    for _ in range(Int(num) - len(self.synths)):
                        self.synths.append(StereoBeatingSines(self.world_ptr, random_exp_float64(100.0, 1000.0)))
                else:
                    # remove some
                    for _ in range(len(self.synths) - Int(num)):
                        _ = self.synths.pop()