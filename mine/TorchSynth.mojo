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
    var models: List[MLP]  # Placeholder for the model
    var current_model: Int
    var model_out_size: Int64
    var inference_trig: Impulse

    var button: Float64
    var button_lag: Lag
    var volume: Float64

    var lags: List[Lag]
    var lag_vals: List[Float64]

    var fb: Float64

    var latch1: Latch
    var latch2: Latch
    var impulse1: Impulse
    var impulse2: Impulse

    var filt1: Reson
    var filt2: Reson

    var dc1: DCTrap
    var dc2: DCTrap

    var toggle_inference: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc1 = Osc(world_ptr)
        self.osc2 = Osc(world_ptr)

        self.model_out_size = 18

        self.model_input = List[Float64](0.0, 0.0, 0.0)

        # initialize the output of the nn with self.model_out_size elements
        self.model_output = List[Float64]()
        for _ in range(self.model_out_size):
            self.model_output.append(0.0)

        self.toggle_inference = 1.0
        self.button = 0.0
        self.button_lag = Lag(self.world_ptr)
        self.volume = 0.0

        self.models = List[MLP]()
        # load the trained model
        try:
            self.models.append(MLP("mine/model_traced0.pt", 3, self.model_out_size))
            self.models.append(MLP("mine/model_traced1.pt", 3, self.model_out_size))
            self.models.append(MLP("mine/model_traced2.pt", 3, self.model_out_size))
            self.models.append(MLP("mine/model_traced3.pt", 3, self.model_out_size))
        except Exception:
            print("Error loading model")
            self.toggle_inference = 0.0

        self.current_model = 0

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
        self.filt1 = Reson(self.world_ptr)
        self.filt2 = Reson(self.world_ptr)
        self.dc1 = DCTrap(self.world_ptr)
        self.dc2 = DCTrap(self.world_ptr)

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> SIMD[DType.float64, 2]:
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

        osc1 = self.filt1.lpf(osc1, linexp(self.lag_vals[5], 0.0, 1.0, 100.0, 20000.0), linlin(self.lag_vals[6], 0.0, 1.0, 0.707, 4.0), linlin(self.lag_vals[7], 0.0, 1.0, 1.0, 10.0))

        tanh_gain = linlin(self.lag_vals[8], 0.0, 1.0, 0.5, 10.0)
        osc1 = vtanh(osc1, tanh_gain, 0.0)

        # get rid of dc offset
        osc1 = self.dc1.next(osc1)

        # oscillator 2

        var freq2 = linlin(self.lag_vals[9], 0.0, 1.0, 2.0, 5000.0) + (linlin(self.lag_vals[10], 0.0, 1.0, 2.0, 5000.0) * osc1)
        var which_osc2 = self.lag_vals[11]

        osc_frac2 = linlin(self.lag_vals[12], 0.0, 1.0, 0.0, 1.0)
        var osc2 = self.osc2.next2(freq2, 0.0, 0.0, [0,4,5,6], osc_frac2, 2, 4)

        osc2 = self.latch2.next(osc2, self.impulse2.next(linexp(self.lag_vals[13], 0.0, 1.0, 100.0, self.world_ptr[0].sample_rate*0.5)))

        osc2 = self.filt2.lpf(osc2, linexp(self.lag_vals[14], 0.0, 1.0, 100.0, 20000.0), linlin(self.lag_vals[15], 0.0, 1.0, 0.707, 4.0), linlin(self.lag_vals[16], 0.0, 1.0, 1.0, 10.0))

        tanh_gain = linlin(self.lag_vals[17], 0.0, 1.0, 0.5, 10.0)
        osc2 = vtanh(osc2, tanh_gain, 0.0)
        osc2 = self.dc2.next(osc2)
        self.fb = osc2

        button = self.button_lag.next(self.button, 0.01)
        oscs = SIMD[DType.float64, 2](osc1, osc2)
        oscs = oscs * self.volume * button
        return oscs

    fn get_msgs(mut self, infer: Float64):
        # name, self.x_axis, self.y_axis, self.z_axis, self.throttle, self.joystick_button, *self.buttons

        # only will grab messages at the top of the audio block
        if self.world_ptr[0].grab_messages == 1:
            toggle_inference = self.world_ptr[0].get_msg("toggle_inference")
            if toggle_inference:
                self.toggle_inference = toggle_inference.value()[0]
                self.volume = 0.2
                self.button = 1.0
            load_msg = self.world_ptr[0].get_text_msg("load_mlp_training0")
            if load_msg:
                print("loading new model", end="\n")
                self.models[0] = MLP(load_msg.value()[0], 3, self.model_out_size)
            load_msg = self.world_ptr[0].get_text_msg("load_mlp_training1")
            if load_msg:
                print("loading new model", end="\n")
                self.models[1] = MLP(load_msg.value()[0], 3, self.model_out_size)
            load_msg = self.world_ptr[0].get_text_msg("load_mlp_training2")
            if load_msg:
                print("loading new model", end="\n")
                self.models[2] = MLP(load_msg.value()[0], 3, self.model_out_size)
            load_msg = self.world_ptr[0].get_text_msg("load_mlp_training3")
            if load_msg:
                print("loading new model", end="\n")
                self.models[3] = MLP(load_msg.value()[0], 3, self.model_out_size)

            if self.toggle_inference:
                joystick = self.world_ptr[0].get_msg("thrustmaster")
                if joystick:
                    self.model_input[0] = joystick.value()[0]
                    self.model_input[1] = joystick.value()[1]
                    self.model_input[2] = joystick.value()[2]
                    self.button = joystick.value()[5]
                    self.volume = 1.0-joystick.value()[3]
                    if joystick.value()[9] > 0.0:
                        self.current_model = 0
                    elif joystick.value()[10] > 0.0:
                        self.current_model = 1
                    elif joystick.value()[11] > 0.0:
                        self.current_model = 2
                    elif joystick.value()[12] > 0.0:
                        self.current_model = 3
                if infer > 0.0:
                    try:
                        self.model_output = self.models[self.current_model].next(self.model_input)  
                    except Exception:
                        print("Inference error in MLP model", end="\n")
                
            else:
                for i in range(self.model_out_size):
                    out = self.world_ptr[0].get_msg("fake_model_output"+String(i))
                    if out:
                        self.model_output[i] = out.value()[0]
            # doing the lags only at the top of the audio block
            # these seems to make very little difference in cpu use
            # for i in range(self.model_out_size):
            #     self.lag_vals[i] = self.lags[i].next_kr(self.model_output[i], 0.1)
