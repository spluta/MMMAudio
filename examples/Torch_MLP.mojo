from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_utils.Messengers import *

from mmm_dsp.Osc import *
from math import tanh
from random import random_float64
from mmm_dsp.Filters import *

from mmm_dsp.MLP import MLP
from mmm_dsp.Distortion import *
from sys import simd_width_of

alias simd_width = simd_width_of[DType.float64]() * 2
alias model_out_size = 16  # Define the output size of the model
alias num_simd = (model_out_size + simd_width - 1) // simd_width  # Calculate number of SIMD groups needed

# THE SYNTH - is imported from TorchSynth.mojo in this directory
struct TorchSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var osc1: Osc[1, 2, 1]
    var osc2: Osc[1, 2, 1]

    var model: MLP[2, model_out_size]  # Instance of the MLP model - 2 inputs, model_out_size outputs
    var lags: List[Lag[simd_width]]  
    var lag_vals: List[Float64]

    var fb: Float64

    var latch1: Latch
    var latch2: Latch
    var impulse1: Impulse
    var impulse2: Impulse

    var filt1: SVF
    var filt2: SVF

    var dc1: DCTrap
    var dc2: DCTrap

    var received_outputs: List[Float64]
    var toggle_receive_outputs: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc1 = Osc[1, 2, 1](world_ptr)
        self.osc2 = Osc[1, 2, 1](world_ptr)

        # load the trained model
        self.model = MLP(world_ptr,"examples/nn_trainings/model_traced.pt", trig_rate=25.0)

        # make a lag for each output of the nn - pair them in twos for SIMD processing
        # self.lag_vals = InlineArray[Float64, model_out_size](fill=random_float64())
        self.lag_vals = [random_float64() for _ in range(model_out_size)]
        self.lags = [Lag[simd_width](self.world_ptr, 1/25.0) for _ in range(num_simd)]

        # create a feedback variable so each of the oscillators can feedback on each sample
        self.fb = 0.0

        self.latch1 = Latch(self.world_ptr)
        self.latch2 = Latch(self.world_ptr)
        self.impulse1 = Impulse(self.world_ptr)
        self.impulse2 = Impulse(self.world_ptr)
        self.filt1 = SVF(self.world_ptr)
        self.filt2 = SVF(self.world_ptr)
        self.dc1 = DCTrap(self.world_ptr)
        self.dc2 = DCTrap(self.world_ptr)

        self.received_outputs = List[Float64]()
        self.toggle_receive_outputs = 0

    fn __repr__(self) -> String:
        return String("OscSynth")

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.model.model_input[0] = self.world_ptr[0].mouse_x
        self.model.model_input[1] = self.world_ptr[0].mouse_y

        self.model.next()  # Run the model inference

        @parameter
        for i in range(num_simd):
            # process each lag group
            model_output_simd = SIMD[DType.float64, simd_width](0.0)
            for j in range(simd_width):
                idx = i * simd_width + j
                if idx < model_out_size:
                    model_output_simd[j] = self.model.model_output[idx]
            lagged_output = self.lags[i].next(model_output_simd)
            for j in range(simd_width):
                idx = i * simd_width + j
                if idx < model_out_size:
                    self.lag_vals[idx] = lagged_output[j]

        # uncomment to see the output of the model
        # var output_str = String("")
        # for i in range(len(self.lag_vals)):
        #     output_str += String(self.lag_vals[i]) + " "
        # self.world_ptr[0].print(output_str)

        # oscillator 1 -----------------------

        var freq1 = linexp(self.lag_vals[0], 0.0, 1.0, 1.0, 3000) + (linlin(self.lag_vals[1], 0.0, 1.0, 2.0, 5000.0) * self.fb)
        # var which_osc1 = lag_vals[2] #not used...whoops

        # next_interp implements a variable wavetable oscillator between the N provided wave types
        # in this case, we are using 0, 4, 5, 6 - Sine, BandLimited Tri, BL Saw, BL Square
        osc_frac1 = linlin(self.lag_vals[3], 0.0, 1.0, 0.0, 1.0)
        osc1 = self.osc1.next_interp(freq1, 0.0, False, [0,4,5,6], osc_frac1)

        # samplerate reduction
        osc1 = self.latch1.next(osc1, self.impulse1.next_bool(linexp(self.lag_vals[4], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))
        osc1 = self.filt1.lpf(osc1, linexp(self.lag_vals[5], 0.0, 1.0, 100.0, 20000.0), linlin(self.lag_vals[6], 0.0, 1.0, 0.707, 4.0))

        tanh_gain = linlin(self.lag_vals[7], 0.0, 1.0, 0.5, 10.0)

        # get rid of dc offset
        osc1 = tanh(osc1*tanh_gain)
        osc1 = self.dc1.next(osc1)

        # oscillator 2 -----------------------

        var freq2 = linlin(self.lag_vals[8], 0.0, 1.0, 2.0, 5000.0) + (linlin(self.lag_vals[9], 0.0, 1.0, 2.0, 5000.0) * osc1)
        # var which_osc2 = self.lag_vals[10] #not used...whoops

        osc_frac2 = linlin(self.lag_vals[11], 0.0, 1.0, 0.0, 1.0)
        var osc2 = self.osc2.next_interp(freq2, 0.0, False, [0,4,5,6], osc_frac2)

        osc2 = self.latch2.next(osc2, self.impulse2.next_bool(linexp(self.lag_vals[12], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))

        osc2 = self.filt2.lpf(osc2, linexp(self.lag_vals[13], 0.0, 1.0, 100.0, 20000.0), linlin(self.lag_vals[14], 0.0, 1.0, 0.707, 4.0))

        tanh_gain = linlin(self.lag_vals[15], 0.0, 1.0, 0.5, 10.0)
        osc2 = tanh(osc2*tanh_gain)
        osc2 = self.dc2.next(osc2)
        self.fb = osc2

        return SIMD[DType.float64, 2](osc1, osc2) * 0.2


# THE GRAPH

struct Torch_Mlp(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var torch_synth: TorchSynth  # Instance of the TorchSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.torch_synth = TorchSynth(world_ptr)  # Initialize the TorchSynth with the world instance

    fn __repr__(self) -> String:
        return String("Torch_Mlp")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        return self.torch_synth.next()