from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Osc import Osc
from random import random_float64
from mmm_dsp.Pan import Pan2
from mmm_dsp.OscBuffers import OscBuffers

# THE SYNTH

struct OscSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var oscs: Osc[2]  # An Osc instance with two internal Oscs
    var osc_freqs: SIMD[DType.float64, 2] 
    var pan: Pan2
    var pan_osc: Osc
    var pan_freq: Float64
    var vol_osc: Osc
    var vol_osc_freq: Float64
    var temp: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], center_freq: Float64):
        self.world_ptr = world_ptr
        self.oscs = Osc[2](world_ptr)  # Initialize two Osc instances

        self.pan = Pan2()
        self.pan_osc = Osc(world_ptr)
        self.pan_freq = random_float64(0.03, 0.1)

        self.vol_osc = Osc(world_ptr)
        self.vol_osc_freq = random_float64(0.05, 0.2)
        self.osc_freqs = SIMD[DType.float64, 2](
            center_freq + random_float64(1.0, 5.0),
            center_freq - random_float64(1.0, 5.0)
        )
        self.temp = 0.0

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        temp = self.oscs.next(self.osc_freqs, interp = 0, os_index = 0) 

        temp = temp * (self.vol_osc.next(self.vol_osc_freq) * 0.01 + 0.01) 

        temp2 = temp[0] + temp[1]  # Combine the two channels into a mono signal

        pan_loc = self.pan_osc.next(self.pan_freq)  # Get pan position

        return self.pan.next(temp2, pan_loc)  # Pan the temp signal

# THE GRAPH

struct ManyOscillators(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

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