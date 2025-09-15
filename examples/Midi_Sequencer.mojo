from mmm_src.MMMWorld import MMMWorld

from mmm_utils.functions import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import *
from mmm_dsp.Env import Env

from mmm_src.MMMTraits import *


struct TrigSynthVoice(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var env: Env

    var mod: Osc
    var car: Osc
    var lag: Lag

    var trig: Float64
    var freq: Float64

    var vol: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.mod = Osc(self.world_ptr)
        self.car = Osc(self.world_ptr)
        self.lag = Lag(self.world_ptr)

        self.env = Env(self.world_ptr)

        self.trig = 0.0
        self.freq = 100.0
        self.vol = 1.0

    fn next(mut self) -> Float64:
        if not self.env.is_active and self.trig <= 0.0:
            return 0.0  # Return 0 if the envelope is not active and no trigger
        else:
            var mod_value = self.mod.next(self.freq*1.5)  # Get the next value from the modulator
            var env = self.env.next([0.0, 1.0, 0.75, 0.75, 0.0], [0.01, 0.1, 0.2, 0.5], [1.0], 0, self.trig)
            var mod_mult = linlin(env, 0.0, 1.0, 0.0, 0.25) # self.lag.next(linlin(self.mouse_x, 0.0, 1.0, 0.0, 8.0), 0.05)
            var car_value = self.car.next(self.freq, mod_value * mod_mult, osc_type=2, os_index=1)  # Get the next value from the carrier
            car_value = car_value * 0.1 * env * self.vol

            return car_value

struct TrigSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var voices: List[TrigSynthVoice]
    var current_voice: Int64
    var trig: Float64
    var freq: Float64
    var num_voices: Int64
    var note_ons: List[List[Int64]]
    var ccs: List[List[Int64]]

    var svf: SVF
    var filt_lag: Lag
    var filt_freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_voices: Int64 = 8):
        self.world_ptr = world_ptr
        self.trig = 0.0
        self.freq = 100.0
        self.num_voices = num_voices
        self.current_voice = 0

        self.note_ons = List[List[Int64]]()
        self.ccs = List[List[Int64]]()

        self.voices = List[TrigSynthVoice]()
        for _ in range(self.num_voices):
            self.voices.append(TrigSynthVoice(self.world_ptr))

        self.svf = SVF(self.world_ptr)
        self.filt_lag = Lag(self.world_ptr)
        self.filt_freq = 1000.0

    fn __repr__(self) -> String:
        return String("OscSynth")

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.get_msgs()

        var out = 0.0

        for note_on in self.note_ons:
            print(note_on[0], note_on[1], note_on[2], end = "\n")
            self.current_voice = (self.current_voice + 1) % self.num_voices
            self.voices[self.current_voice].vol = Float64(note_on[2]) / 127.0
            self.voices[self.current_voice].trig = 1.0
            self.voices[self.current_voice].freq = midicps(note_on[1])
        self.note_ons.clear()

        # looking for midi cc on cc 34
        # this will control the frequency of the filter
        for cc in self.ccs:
            if cc[1] == 34:  # Assuming CC 34 is for filter frequency
                self.filt_freq = linlin(Float64(cc[2]), 0.0, 127.0, 20.0, 1000.0)  # Map CC value to frequency range

        if self.trig > 0.0:
            self.current_voice = (self.current_voice + 1) % self.num_voices
            self.voices[self.current_voice].trig = self.trig
            self.voices[self.current_voice].freq = self.freq

        # get the output of all the synths and reset the of the current voice (after getting audio)
        for i in range(len(self.voices)):
            out += self.voices[i].next()
            self.trig = 0.0
            self.voices[i].trig = 0.0  # Reset the trigger for the next iteration

        out = self.svf.lpf(out, self.filt_lag.next(self.filt_freq, 0.1), 2.0) * 0.6

        return out

    fn get_msgs(mut self: Self):
        # calls to get_msg and get_midi return an Optional type
        # so you must get the value, then test the value to see if it exists, before using the value
        # get_msg returns a single list of values while get_midi returns a list of lists of values

        trig = self.world_ptr[0].get_msg("t_trig") # trig will be an Optional
        if trig: # if it trig is None, we do nothing
            self.trig = trig.value()[0]
        freq = self.world_ptr[0].get_msg("trig_seq_freq")
        if freq:
            self.freq = freq.value()[0]
        note_ons = self.world_ptr[0].get_midi("note_on",-1, -1)  # Get all note on messages
        if note_ons:
            self.note_ons = note_ons.value().copy()
        
        ccs = self.world_ptr[0].get_midi("control_change",-1, -1)
        if ccs:
            self.ccs = ccs.value().copy()

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

