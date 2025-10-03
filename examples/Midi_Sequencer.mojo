from mmm_src.MMMWorld import *
from mmm_utils.Messengers import *

from mmm_utils.functions import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import *
from mmm_dsp.Env import Env

from mmm_src.MMMTraits import *

# Synth Voice - Below is a polyphonic synth. The first struct, TrigSynthVoice, is a single voice of the synth. Each voice is made up of a modulator oscillator, a carrier oscillator, and an envelope generator. 

struct TrigSynthVoice(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var env: Env

    var mod: Osc
    var car: Osc[1, 0, 1]
    var lag: Lag

    var trig: Float64
    var freq: Float64

    var vol: Float64

    var values: List[Float64]
    var times: List[Float64]
    var curves: List[Float64]
    var bend_mul: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.mod = Osc(self.world_ptr)
        self.car = Osc[1, 0, 1](self.world_ptr)
        self.lag = Lag(self.world_ptr)

        self.env = Env(self.world_ptr)

        self.trig = 0.0
        self.freq = 100.0
        self.vol = 1.0

        # you may be tempted to make these lists inside the next() function, but that would be bad
        # because it would create new lists every sample, which would be slow and cause memory issues
        # instead, we make the lists once here in the __init__ function, and then just change their values in next() if you want to
        self.values = [0.0, 1.0, 0.75, 0.75, 0.0]
        self.times = [0.01, 0.1, 0.2, 0.5]
        self.curves = [1.0]
        self.bend_mul = 1.0

    @always_inline
    fn next(mut self) -> Float64:
        # if there is no trigger and the envelope is not active, that means the voice should be silent - output 0.0
        if not self.env.is_active and self.trig <= 0.0:
            return 0.0
        else:
            bend_freq = self.freq * self.bend_mul
            var mod_value = self.mod.next(bend_freq * 3.0)  # Modulator frequency is 3 times the carrier frequency
            var env = self.env.next(self.values, self.times, self.curves, 0, self.trig)
            var mod_mult = env * 0.25
            var car_value = self.car.next(bend_freq, mod_value * mod_mult, osc_type=2)  
            car_value = car_value * 0.1 * env * self.vol

            return car_value


struct TrigSynth(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var voices: List[TrigSynthVoice]
    var current_voice: Int64

    # the following 5 variables are messengers (imported from mmm_utils.Messengers.mojo)
    # messengers get their values from the MMMWorld message system when told to, usually once per block
    # they then store that value received internally, and you can access it as a normal variable
    var trig: Messenger
    var freq: Messenger
    var note_ons: MIDIMessenger
    var ccs: MIDIMessenger
    var bends: MIDIMessenger

    var num_voices: Int64

    var svf: SVF
    var filt_lag: Lag
    var filt_freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_voices: Int64 = 8):
        self.world_ptr = world_ptr
        self.trig = Messenger(world_ptr, 0.0)
        self.freq = Messenger(world_ptr, 100.0)
        self.num_voices = num_voices
        self.current_voice = 0

        self.note_ons = MIDIMessenger(world_ptr)
        self.ccs = MIDIMessenger(world_ptr)
        self.bends = MIDIMessenger(world_ptr)

        self.voices = List[TrigSynthVoice]()
        for _ in range(self.num_voices):
            self.voices.append(TrigSynthVoice(self.world_ptr))

        self.svf = SVF(self.world_ptr)
        self.filt_lag = Lag(self.world_ptr)
        self.filt_freq = 1000.0

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        var out = 0.0

        # these messages are only processed on the first sample of the block, when grab_messages==1, so we should only do these things on the first sample of the block
        if self.world_ptr[0].grab_messages == 1:
            self.trig.get_msg("t_trig")
            self.freq.get_msg("trig_seq_freq")
            self.note_ons.get_note_ons(0, -1)  # Get all note ons on channel 0
            self.ccs.get_ccs(0, 34)  # Get all CCs on channel 0, CC 34
            self.bends.get_bends(0)  # Get all pitch bend messages on channel 0

            for bend in self.bends.value:
                bend_mul = linlin(Float64(bend[1]), -8192.0, 8191.0, 0.935, 1.065)  # Map bend value to a multiplier (up and down a semitone)
                for i in range(len(self.voices)):
                    self.voices[i].bend_mul = bend_mul

            # go through the list of note_ons received and play them
            for note_on in self.note_ons.value:
                self.current_voice = (self.current_voice + 1) % self.num_voices
                self.voices[self.current_voice].vol = Float64(note_on[2]) / 127.0
                self.voices[self.current_voice].trig = 1.0
                self.voices[self.current_voice].freq = midicps(Float64(note_on[1]))

            # looking for midi cc on cc 34
            # this will control the frequency of the filter
            for cc in self.ccs.value:
                if cc[1] == 34:  # Assuming CC 34 is for filter frequency
                    self.filt_freq = linlin(Float64(cc[2]), 0.0, 127.0, 20.0, 1000.0)  # Map CC value to frequency range

            if self.trig.value > 0.0:
                self.current_voice = (self.current_voice + 1) % self.num_voices
                self.voices[self.current_voice].trig = self.trig.value
                self.voices[self.current_voice].freq = self.freq.value

        # get the output of all the synths
        for i in range(len(self.voices)):
            out += self.voices[i].next()

        # reset the triggers on all the voices on the first sample of the block
        if self.world_ptr[0].grab_messages == 1:
            for i in range(len(self.voices)):
                self.trig.value = 0.0
                self.voices[i].trig = 0.0  # Reset the trigger for the next iteration

        out = self.svf.lpf(out, self.filt_lag.next(self.filt_freq, 0.1), 2.0) * 0.6

        return out
        

struct Midi_Sequencer(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples

    var trig_synth: TrigSynth  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.output = List[Float64](0.0, 0.0)  # Initialize output list

        self.trig_synth = TrigSynth(world_ptr)  # Initialize the TrigSynth with the world instance

    fn __repr__(self) -> String:
        return String("Midi_Sequencer")

    fn next(mut self: Midi_Sequencer) -> SIMD[DType.float64, 2]: 
        return self.trig_synth.next()  # Return the combined output sample

