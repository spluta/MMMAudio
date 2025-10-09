from mmm_src.MMMWorld import *
from mmm_utils.Messengers import *

from mmm_utils.functions import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import *
from mmm_dsp.Env import *

from mmm_src.MMMTraits import *

# Synth Voice - Below is a polyphonic synth. The first struct, TrigSynthVoice, is a single voice of the synth. Each voice is made up of a modulator oscillator, a carrier oscillator, and an envelope generator. 

struct TrigSynthVoice(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var env_params: EnvParams
    var env: Env

    var mod: Osc
    var car: Osc[1, 0, 1]
    var sub: Osc

    var trig: Float64
    var freq: Float64

    var vol: Float64

    var bend_mul: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.mod = Osc(self.world_ptr)
        self.car = Osc[1, 0, 1](self.world_ptr)
        self.sub = Osc(self.world_ptr)

        self.env_params = EnvParams([0.0, 1.0, 0.75, 0.75, 0.0], [0.01, 0.1, 0.2, 0.5], [1.0])
        self.env = Env(self.world_ptr)

        self.trig = 0.0
        self.freq = 100.0
        self.vol = 1.0

        self.bend_mul = 1.0

    @always_inline
    fn next(mut self) -> Float64:
        # if there is no trigger and the envelope is not active, that means the voice should be silent - output 0.0
        if not self.env.is_active and self.trig<= 0.0:
            return 0.0
        else:
            bend_freq = self.freq * self.bend_mul
            var mod_value = self.mod.next(bend_freq * 1.5)  # Modulator frequency is 3 times the carrier frequency
            var env = self.env.next(self.env_params, self.trig)

            var mod_mult = env * 0.5
            var car_value = self.car.next(bend_freq, mod_value * mod_mult, osc_type=2)  
            
            self.trig = 0.0  # reset the trigger after using it

            car_value += self.sub.next(bend_freq * 0.5) # Add a sub oscillator one octave below the carrier
            car_value = car_value * 0.1 * env * self.vol

            return car_value


struct TrigSynth(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var voices: List[TrigSynthVoice]
    var current_voice: Int64

    # the following 5 variables are messengers (imported from mmm_utils.Messengers.mojo)
    # messengers get their values from the MMMWorld message system when told to, usually once per block
    # they then store that value received internally, and you can access it as a normal variable
    var messenger: Messenger

    var num_voices: Int64

    var svf: SVF
    var filt_lag: Lag
    var filt_freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_voices: Int64 = 8):
        self.world_ptr = world_ptr
        self.num_voices = num_voices
        self.current_voice = 0

        self.messenger = Messenger(self.world_ptr)

        self.voices = List[TrigSynthVoice]()
        for _ in range(self.num_voices):
            self.voices.append(TrigSynthVoice(self.world_ptr))

        self.svf = SVF(self.world_ptr)
        self.filt_lag = Lag(self.world_ptr)
        self.filt_freq = 1000.0

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.world_ptr[0].block_state == 0:
        #     # these messages are only processed on the first sample of the block, when block_state==0, so we should only do these things on the first sample of the block
            notes = self.messenger.val_lists("note_on")  # get the lists of note_on messages received this block


        #     # go through the list of note_ons received and play them
        #     # if no note ons were received, the list will be empty and this loop will be skipped
            for ref note_on in notes:
                self.current_voice = (self.current_voice + 1) % self.num_voices
                self.voices[self.current_voice].vol = note_on[2] / 127.0
                self.voices[self.current_voice].trig = 1.0
                self.voices[self.current_voice].freq = midicps(note_on[1])

        #     ccs = self.messenger.val_lists("control_change")
        #     for cc in ccs:
        #         if cc[1] == 34:
        #             self.filt_freq = cc[2]

        #     # # i am only expecting one pitch bend message per block, so just get the first list in the lists of lists
        #     bends = self.messenger.val_list("pitchwheel")  

        #     if len(bends) > 0:
        #         for i in range(len(self.voices)):
        #             self.voices[i].bend_mul = bends[0]


        var out = 0.0
        # get the output of all the synths
        for i in range(len(self.voices)):
            out += self.voices[i].next()

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

