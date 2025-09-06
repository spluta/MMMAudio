from mmm_src.MMMWorld import MMMWorld
from examples.synths.OscSynth import OscSynth
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from sys.info import simdwidthof

struct ManyOscillators(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples
    var osc_synths: List[OscSynth]  # Instances of the Oscillator
    var num_pairs: Int

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        print("ManyOscillators initialized with num_chans:", self.world_ptr[0].num_chans)

        # initialize the list of oscillator pairs
        self.osc_synths = List[OscSynth]()
        # add 10 pairs to the list
        self.num_pairs = 10
        for _ in range(self.num_pairs):
            self.osc_synths.append(OscSynth(self.world_ptr, random_exp_float64(100.0, 1000.0)))  

        self.output = List[Float64]()  # Initialize output list

        for _ in range(self.world_ptr[0].num_chans):
            self.output.append(0.0)  # Initialize output list with zeros

    fn __repr__(self) -> String:
        return String("ManyOscillators")

    fn next(mut self) -> List[Float64]:
        self.get_msgs()

        # SIMD can make this much more efficient
        # below are two versions of the same process - one using Lists and one using a 2 value SIMD vector
        # the SIMD version saves around 5-6% on my cpu
        if False:

            zero(self.output)  # Clear the output list
            
            for i in range(self.num_pairs):
                mix(self.output, self.osc_synths[i].next())
        else:
            simd_sum = SIMD[DType.float64, 2](0.0, 0.0)
            for i in range(self.num_pairs):
                simd_sum += self.osc_synths[i].next_simd()

            self.output = [simd_sum[0], simd_sum[1]]

        return self.output  # Return the combined output samples

    fn get_msgs(mut self):
        # looking for a message that changes the number of osc pairs

        num = self.world_ptr[0].get_msg("set_num_pairs")
        if num:
            if num.value()[0] != self.num_pairs:
                print("Changing number of osc pairs to:", Int(num.value()[0]))
                # adjust the list of osc synths
                if Int(num.value()[0]) > self.num_pairs:
                    # add more
                    for _ in range(Int(num.value()[0]) - self.num_pairs):
                        self.osc_synths.append(OscSynth(self.world_ptr, random_exp_float64(100.0, 1000.0)))  
                else:
                    # remove some
                    for _ in range(self.num_pairs - Int(num.value()[0])):
                        _ = self.osc_synths.pop()
            self.num_pairs = Int(num.value()[0])