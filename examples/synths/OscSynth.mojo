from mmm_dsp.Osc import Osc
from random import random_float64
from mmm_dsp.Pan import Pan2
from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.OscBuffers import OscBuffers
from mmm_utils.functions import *

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

        self.temp = 0.0
        for i in range(len(self.oscs)):
            self.temp += self.oscs[i].next(self.osc_freqs[i], interp = 0, os_index = 0)  # Get the next value from the Osc

        self.temp = self.temp * (self.vol_osc.next(self.vol_osc_freq) * 0.01 + 0.01) # Apply volume modulation

        pan_loc = self.pan_osc.next(self.pan_freq)  # Get pan position

        return self.pan.next_simd(self.temp, pan_loc)  # Pan the temp signal