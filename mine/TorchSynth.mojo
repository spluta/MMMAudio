from mmm_dsp.Osc import *
from mmm_utils.functions import *
from math import tanh
from random import random_float64
from mmm_dsp.Pan2 import Pan2
from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.OscBuffers import OscBuffers
from mmm_dsp.Filters import Lag

from mmm_dsp.MLP import MLP
from mmm_dsp.Distortion import *


struct TorchSynth(Representable, Movable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var osc_buffers: OscBuffers  # Buffer for oscillators
    var oscs: List[Osc]  # List of Osc instances
    var sample_rate: Float64
    var mouse_x: Float64
    var mouse_y: Float64

    var model_input: List[Float64]  # Input list for audio synthesis
    var model_output: List[Float64]  # Placeholder for output data
    var model: MLP  # Placeholder for the model

    var model_out_size: Int64

    var lag: Lag

    var lags: List[Lag]

    var fb: List[Float64]

    var latches: List[Latch]  # Placeholder for latches
    var trigs: List[Impulse]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.sample_rate = self.world_ptr[0].sample_rate
        self.oscs = List[Osc]()
        self.oscs.append(Osc(self.world_ptr))
        self.oscs.append(Osc(self.world_ptr))
        self.oscs.append(Osc(self.world_ptr))
        self.oscs.append(Osc(self.world_ptr))

        self.osc_buffers = self.world_ptr[0].osc_buffers  # Initialize with the world's oscillator buffers

        self.mouse_x = 0.0  # Initialize mouse x position
        self.mouse_y = 0.0  # Initialize mouse y position

        self.model_out_size = 13

        self.model_input = List[Float64](0.0, 0.0)  # Initialize input list with two elements
        self.model_output = List[Float64]()
        for _ in range(self.model_out_size):
            self.model_output.append(0.0)  # Initialize output list with zeros
        self.model = MLP("/Users/spluta1/Dev/python/pyaudio_mojo_test/trainings/model_traced.pt", 2, self.model_out_size)  # Initialize the MLP model

        self.lag = Lag(self.world_ptr)  # Initialize the Lag instance

        self.lags = List[Lag]()
        for _ in range(self.model_out_size):
            self.lags.append(Lag(self.world_ptr))

        self.fb = List[Float64](0.0, 0.0, 0.0, 0.0)

        self.latches = List[Latch]()
        self.trigs = List[Impulse]()
        for _ in range(4):
            self.latches.append(Latch(self.world_ptr))
            self.trigs.append(Impulse(self.world_ptr))

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> List[Float64]:
        var osc_sum = List[Float64](0.0, 0.0)


        if self.model_input[0] != self.mouse_x or self.model_input[1] != self.mouse_y:
            # print("mouse_x:", self.mouse_x, "mouse_y:", self.mouse_y)  # Debug
            self.model_input[0] = self.mouse_x
            self.model_input[1] = self.mouse_y
            try:
                self.model_output = self.model.next(self.model_input)  # Process the input through the MLP model
            except Exception:
                print("Inference error in MLP model")

            # print("MLP output:", end=" ")  # Debug print for MLP output
            # for i in range(len(self.output)):
            #     print(self.output[i], end=" ")
            # print()
        for i in range(self.model_out_size):
            _ = self.lags[i].next(self.model_output[i], 0.1)


        var freq0 = linlin(self.lags[0].val, 0.0, 1.0, 2.0, 5000.0)
        var freq1 = linlin(self.lags[1].val, 0.0, 1.0, 2.0, 5000.0)
        var mod0 = linlin(self.lags[2].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[1] + linlin(self.lags[3].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[2] + linlin(self.lags[4].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[3]

        var mod1 = linlin(self.lags[5].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[2] + linlin(self.lags[6].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[3] + linlin(self.lags[7].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[4]

        var mod2 = linlin(self.lags[8].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[3] + linlin(self.lags[9].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[4] + linlin(self.lags[10].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[1]

        var mod3 = linlin(self.lags[11].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[0] + linlin(self.lags[12].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[1] + linlin(self.lags[1].val, 0.0, 1.0, 0.0, 4000.0)*self.fb[2]

        var th_gain_0 = linlin(self.lags[0].val, 0.0, 1.0, 1.0, 10.0)
        var th_offset_0 = linlin(self.lags[1].val, 0.0, 1.0, 0.0, 1.0)
        var th_gain_1 = linlin(self.lags[2].val, 0.0, 1.0, 1.0, 10.0)
        var th_offset_1 = linlin(self.lags[3].val, 0.0, 1.0, 0.0, 1.0)
        var th_gain_2 = linlin(self.lags[4].val, 0.0, 1.0, 1.0, 10.0)
        var th_offset_2 = linlin(self.lags[5].val, 0.0, 1.0, 0.0, 1.0)
        var th_gain_3 = linlin(self.lags[6].val, 0.0, 1.0, 1.0, 10.0)
        var th_offset_3 = linlin(self.lags[7].val, 0.0, 1.0, 0.0, 1.0)

        var osc_frac0 = self.lags[4].val
        var osc_frac1 = self.lags[5].val
        var osc_frac2 = self.lags[6].val
        var osc_frac3 = self.lags[7].val

        var temp0 = self.oscs[0].next2(freq0+mod0, 0.0, 0.0, [0,4,5,6], osc_frac0, 2, 1)
        var temp1 = self.oscs[1].next2(freq1+mod1, 0.0, 0.0, [0,4,5,6], osc_frac1, 2, 1)
        var temp2 = self.oscs[2].next2(freq1+mod2, 0.0, 0.0, [0,4,5,6], osc_frac2, 2, 1)
        var temp3 = self.oscs[3].next2(freq1+mod3, 0.0, 0.0, [0,4,5,6], osc_frac3, 2, 1)

        temp0 = bitcrusher(temp0, Int64(self.lags[8].val))  
        temp1 = bitcrusher(temp1, Int64(self.lags[8].val)) 
        temp2 = bitcrusher(temp2, Int64(self.lags[8].val)) 
        temp3 = bitcrusher(temp3, Int64(self.lags[8].val)) 

        for i in range(4):
            self.trigs[i].next(imp_freqs[i])

        temp0 = self.latches[0].next(temp0, trigs[0])

        

        self.fb[0] = vtanh(temp0, th_gain_0, th_offset_0)
        self.fb[1] = vtanh(temp1, th_gain_1, th_offset_1)
        self.fb[2] = vtanh(temp2, th_gain_2, th_offset_2)
        self.fb[3] = vtanh(temp3, th_gain_3, th_offset_3)

        osc_sum[0] = temp0
        osc_sum[1] = temp1

        return osc_sum

    # fn send_msgs(mut self: TorchSynth, msg_dict: Dict[String, List[Float64]]) raises -> None:
    #     """Send a message to the TorchSynth."""
    #     if "mouse_x" in msg_dict:
    #         self.mouse_x = msg_dict["mouse_x"][0]
    #     if "mouse_y" in msg_dict:
    #         self.mouse_y = msg_dict["mouse_y"][0]