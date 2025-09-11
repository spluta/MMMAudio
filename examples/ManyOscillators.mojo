from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_utils.Print import Print
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from random import random_float64
from mmm_dsp.Pan import Pan2
from mmm_dsp.OscBuffers import OscBuffers

# THE SYNTH

struct OscSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var oscs: List[Osc]  
    var osc_freqs: List[Float64]  
    var pan: Pan2
    var pan_osc: Osc
    var pan_freq: Float64
    var vol_osc: Osc
    var vol_osc_freq: Float64
    var temp: Float64
    var printer: Print

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], center_freq: Float64):
        self.world_ptr = world_ptr
        self.oscs = List[Osc]()
        for _ in range(2):
            self.oscs.append(Osc(world_ptr))  # Initialize two Osc instances for stereo output

        self.pan = Pan2()
        self.pan_osc = Osc(world_ptr)
        self.pan_freq = random_float64(0.03, 0.1)

        self.vol_osc = Osc(world_ptr)
        self.vol_osc_freq = random_float64(0.05, 0.2)
        self.osc_freqs = List[Float64]()
        self.osc_freqs.append(center_freq+random_float64(1.0,5.0))
        self.osc_freqs.append(center_freq-random_float64(1.0,5.0))
        self.temp = 0.0

        self.printer = Print(world_ptr)

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> List[Float64]:
        
        self.temp = 0.0
        for i in range(len(self.oscs)):
            self.temp += self.oscs[i].next(self.osc_freqs[i], interp = 0, os_index = 0)  # Get the next value from the Osc

        self.temp = self.temp * (self.vol_osc.next(self.vol_osc_freq) * 0.01 + 0.01) # Apply volume modulation

        pan_loc = self.pan_osc.next(self.pan_freq)  # Get pan position

        return self.pan.next(self.temp, pan_loc)  # Pan the temp signal

    fn next_simd(mut self) -> SIMD[DType.float64, 2]:

        self.printer.next(self.osc_freqs[0],"freqs", freq=1.0)

        self.temp = 0.0
        for i in range(len(self.oscs)):
            self.temp += self.oscs[i].next(self.osc_freqs[i], interp = 0, os_index = 0)  # Get the next value from the Osc

        self.temp = self.temp * (self.vol_osc.next(self.vol_osc_freq) * 0.01 + 0.01) # Apply volume modulation

        pan_loc = self.pan_osc.next(self.pan_freq)  # Get pan position

        return self.pan.next_simd(self.temp, pan_loc)  # Pan the temp signal

# THE GRAPH

struct ManyOscillators(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples
    var osc_synths: List[OscSynth]  # Instances of the Oscillator
    var num_pairs: Int

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        # initialize the list of oscillator pairs
        self.osc_synths = List[OscSynth]()
        # add 10 pairs to the list
        self.num_pairs = 10
        for _ in range(self.num_pairs):
            self.osc_synths.append(OscSynth(self.world_ptr, random_exp_float64(100.0, 1000.0)))  

        self.output = List[Float64](0.0, 0.0)  # Initialize output list

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

            return self.output.copy()
        else:
            simd_sum = SIMD[DType.float64, 2](0.0, 0.0)
            for i in range(self.num_pairs):
                simd_sum += self.osc_synths[i].next_simd()

            return [simd_sum[0], simd_sum[1]]

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