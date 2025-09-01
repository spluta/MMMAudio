from mmm_dsp.Osc import *
from mmm_utils.functions import *
from math import tanh
from random import random_float64
from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Filters import *

from mmm_dsp.MLP import MLP
from mmm_dsp.Distortion import *


struct TorchSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var osc1: Osc
    var osc2: Osc 

    var model_input: List[Float64]  # Input list for audio synthesis
    var model_output: List[Float64]  # Placeholder for output data
    var model: MLP  # Placeholder for the model
    var model_out_size: Int64
    var inference_trig: Impulse

    var lags: List[Lag]
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

    var toggle_inference: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc1 = Osc(world_ptr)
        self.osc2 = Osc(world_ptr)

        self.model_out_size = 16

        self.model_input = List[Float64](0.0, 0.0)

        # initialize the output of the nn with self.model_out_size elements
        self.model_output = List[Float64]()
        for _ in range(self.model_out_size):
            self.model_output.append(0.0)

        # load the trained model
        self.model = MLP("examples/nn_trainings/model_traced.pt", 2, self.model_out_size)  

        self.inference_trig = Impulse(self.world_ptr)

        # make a lag for each output of the nn
        self.lags = List[Lag]()
        self.lag_vals = List[Float64]()
        for _ in range(self.model_out_size):
            self.lags.append(Lag(self.world_ptr))
            self.lag_vals.append(0.0)

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

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> List[Float64]:
        infer = self.inference_trig.next(50)
        self.get_msgs(infer)

        for i in range(self.model_out_size):
            self.lag_vals[i] = self.lags[i].next(self.model_output[i], 0.1)

        # oscillator 1

        var freq1 = linexp(self.lag_vals[0], 0.0, 1.0, 1.0, 3000) + (linlin(self.lag_vals[1], 0.0, 1.0, 2.0, 5000.0) * self.fb)
        var which_osc1 = self.lag_vals[2]

        # next2 implements a variable wavetable oscillator between the N provided wave types
        # in this case, we are using 0, 4, 5, 6 - Sine, BandLimited Tri, BL Saw, BL Square
        osc_frac1 = linlin(self.lag_vals[3], 0.0, 1.0, 0.0, 1.0)
        var osc1 = self.osc1.next2(freq1, 0.0, 0.0, [0,4,5,6], osc_frac1, 2, 4)

        # samplerate reduction
        osc1 = self.latch1.next(osc1, self.impulse1.next(linexp(self.lag_vals[4], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))

        osc1 = self.filt1.lpf(osc1, linexp(self.lag_vals[5], 0.0, 1.0, 100.0, 20000.0), linlin(self.lag_vals[6], 0.0, 1.0, 0.707, 4.0))

        tanh_gain = linlin(self.lag_vals[7], 0.0, 1.0, 0.5, 10.0)
        osc1 = vtanh(osc1, tanh_gain, 0.0)

        # get rid of dc offset
        osc1 = self.dc1.next(osc1)

        # oscillator 2

        var freq2 = linlin(self.lag_vals[8], 0.0, 1.0, 2.0, 5000.0) + (linlin(self.lag_vals[9], 0.0, 1.0, 2.0, 5000.0) * osc1)
        var which_osc2 = self.lag_vals[10]

        osc_frac2 = linlin(self.lag_vals[11], 0.0, 1.0, 0.0, 1.0)
        var osc2 = self.osc2.next2(freq2, 0.0, 0.0, [0,4,5,6], osc_frac2, 2, 4)

        osc2 = self.latch2.next(osc2, self.impulse2.next(linexp(self.lag_vals[12], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))

        osc2 = self.filt2.lpf(osc2, linexp(self.lag_vals[13], 0.0, 1.0, 100.0, 20000.0), linlin(self.lag_vals[14], 0.0, 1.0, 0.707, 4.0))

        tanh_gain = linlin(self.lag_vals[15], 0.0, 1.0, 0.5, 10.0)
        osc2 = vtanh(osc2, tanh_gain, 0.0)
        osc2 = self.dc2.next(osc2)
        self.fb = osc2

        return [osc1 * 0.2, osc2 * 0.1]

    fn get_msgs(mut self, infer: Float64):
        # only will grab messages at the top of the audio block
        toggle_inference = self.world_ptr[0].get_msg("toggle_inference")
        if toggle_inference:
            self.toggle_inference = toggle_inference.value()[0]
        load_msg = self.world_ptr[0].get_text_msg("load_mlp_training")
        if load_msg:
            print("loading new model", end="\n")
            self.model = MLP(load_msg.value()[0], 2, self.model_out_size)
        if self.toggle_inference:
            if infer > 0.0:
                self.model_input[0] = self.world_ptr[0].mouse_x
                self.model_input[1] = self.world_ptr[0].mouse_y
                try:
                    self.model_output = self.model.next(self.model_input)  # Process the input through the MLP model
                except Exception:
                    print("Inference error in MLP model", end="\n")
        else:
            for i in range(self.model_out_size):
                out = self.world_ptr[0].get_msg("model_output"+String(i))
                if out:
                    self.model_output[i] = out.value()[0]
