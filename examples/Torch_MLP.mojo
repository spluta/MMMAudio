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

    # var model_input: InlineArray[Float64, 2]  # Input list for audio synthesis
    # var model_output: InlineArray[Float64, model_out_size]  # Output list from the model
    var model_input: List[Float64]  # Input list for audio synthesis
    var model_output: List[Float64]  # Output list from the model
    var model: MLP  # Placeholder for the model
    var inference_trig: Impulse
    var lags: LagN[0.02, model_out_size]  # List of Lag processors for smoothing model outputs
    # var lag_vals: InlineArray[Float64, model_out_size] # flattened list of lagged values
    # var lag_times: InlineArray[Float64, 1]
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

    var text_messenger: TextMessenger
    var toggle_inference: Float64
    var received_outputs: List[Float64]
    var toggle_receive_outputs: Float64
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc1 = Osc[1, 2, 1](world_ptr)
        self.osc2 = Osc[1, 2, 1](world_ptr)

        # self.model_input = InlineArray[Float64, 2](fill=0.0)
        # self.model_output = InlineArray[Float64, model_out_size](fill=0.0)
        self.model_input = [Float64() for _ in range(2)]
        self.model_output = [Float64() for _ in range(model_out_size)]

        # load the trained model
        self.text_messenger = TextMessenger(world_ptr)
        self.model = MLP("examples/nn_trainings/model_traced.pt", 2, model_out_size)

        self.inference_trig = Impulse(self.world_ptr)

        # make a lag for each output of the nn - pair them in twos for SIMD processing
        # self.lag_vals = InlineArray[Float64, model_out_size](fill=random_float64())
        self.lag_vals = [random_float64() for _ in range(model_out_size)]
        self.lags = LagN[0.02, model_out_size](self.world_ptr)

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

        self.toggle_inference = 1.0
        self.received_outputs = List[Float64]()
        self.toggle_receive_outputs = 0
        self.messenger = Messenger(world_ptr)

    fn __repr__(self) -> String:
        return String("OscSynth")

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.world_ptr[0].top_of_block:
            # this will return a tuple (model_path(String), triggered(Bool))
            load_msg = self.text_messenger.get_text_msg_val("load_mlp_training")
            if load_msg != "":
                print("loading new model", end="\n")
                self.model = MLP(load_msg, 2, model_out_size)

            self.toggle_inference = self.messenger.get_val("toggle_inference", 1.0)
            
            if self.toggle_inference <= 0.0:
                triggered = self.messenger.triggered("model_output")
                if triggered:
                    print("receiving model output values", end="\n")
                    model_output = self.messenger.get_list("model_output")
                    num = Int(min(model_out_size, len(model_output)))
                    for i in range(num):
                        self.model_output[i] = model_output[i]

        # inference will only happen at the rate of the impulse
        infer = self.inference_trig.next(25)
        if infer > 0.0 and self.toggle_inference > 0.0:
            self.model_input[0] = self.world_ptr[0].mouse_x
            self.model_input[1] = self.world_ptr[0].mouse_y
            try:
                self.model.next(self.model_input, self.model_output)  # Process the input through the MLP model
            except Exception:
                print("Inference error in MLP model", end="\n")

        # process_list is an experimental feature of Lag that allows SIMD processing of multiple Lags at once
        # this processes the 16 Lags, 2 Lags at a time (like they are grouped)
        # the output is written directly into the lag_vals list

        # self.lags.next(self.model_output, self.lag_vals, [0.01])
        self.lags.next(self.model_output, self.lag_vals)

        # uncomment to see the output of the model
        # var output_str = String("")
        # for i in range(len(self.lag_vals)):
        #     output_str += String(self.lag_vals[i]) + " "
        # self.world_ptr[0].print(output_str)

        # oscillator 1 -----------------------

        var freq1 = linexp(self.lag_vals[0], 0.0, 1.0, 1.0, 3000) + (linlin(self.lag_vals[1], 0.0, 1.0, 2.0, 5000.0) * self.fb)
        # var which_osc1 = lag_vals[2] #not used...whoops

        # next2 implements a variable wavetable oscillator between the N provided wave types
        # in this case, we are using 0, 4, 5, 6 - Sine, BandLimited Tri, BL Saw, BL Square
        osc_frac1 = linlin(self.lag_vals[3], 0.0, 1.0, 0.0, 1.0)
        osc1 = self.osc1.next_interp(freq1, 0.0, False, [0,4,5,6], osc_frac1)

        # samplerate reduction
        osc1 = self.latch1.next(osc1, self.impulse1.next(linexp(self.lag_vals[4], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))
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

        osc2 = self.latch2.next(osc2, self.impulse2.next(linexp(self.lag_vals[12], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))

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