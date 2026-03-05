from mmm_audio import *

# Synth Voice - Below is a polyphonic synth. The first struct, TrigSynthVoice, is a single voice of the synth. Each voice is made up of a modulator oscillator, a carrier oscillator, and an envelope generator. 

struct TrigSynthVoice(Movable, Copyable):
    var world: World  # Pointer to the MMMWorld instance

    var env_params: EnvParams
    var env: Env

    var mod: Osc[]
    var car: Osc[1, Interp.linear, 0]
    var sub: Osc[]

    var bend_mul: Float64

    var note: List[Float64]

    var messenger: Messenger

    fn __init__(out self, world: World, name_space: String = ""):
        self.world = world

        self.mod = Osc(self.world)
        self.car = Osc[1, Interp.linear, 0](self.world)
        self.sub = Osc(self.world)

        self.env_params = EnvParams([0.0, 1.0, 0.75, 0.75, 0.0], [0.01, 0.1, 0.2, 0.5], [1.0])
        self.env = Env(self.world)

        self.bend_mul = 1.0

        self.messenger = Messenger(self.world, name_space)

        self.note = List[Float64]()

    @always_inline
    fn next(mut self) -> Float64:
        make_note = self.messenger.notify_update(self.note, "note")

        # if there is no trigger and the envelope is not active, that means the voice should be silent - output 0.0
        if not self.env.is_active and not make_note:
            return 0.0
        else:
            bend_freq = self.note[0] * self.bend_mul
            var mod_value = self.mod.next(bend_freq * 1.5, osc_type=OscType.sine)  # Modulator frequency is 3 times the carrier frequency
            var env = self.env.next(self.env_params, make_note)  # Trigger the envelope if trig is True

            var mod_mult = env * 0.5 * linlin(bend_freq, 1000, 4000, 1, 0) #decrease the mod amount as freq increases
            var car_value = self.car.next(bend_freq, mod_value * mod_mult, osc_type=OscType.sine)  

            car_value += self.sub.next(bend_freq * 0.5) # Add a sub oscillator one octave below the carrier
            car_value = car_value * 0.1 * env * self.note[1]  # Scale the output by the envelope and note velocity

            return car_value


struct TrigSynth(Movable, Copyable):
    var world: World  # Pointer to the MMMWorld instance

    var voices: List[TrigSynthVoice]
    var current_voice: Int

    # the following 5 variables are messengers (imported from .Messenger_Module.mojo)
    # messengers get their values from the MMMWorld message system when told to, usually once per block
    # they then store that value received internally, and you can access it as a normal variable
    var messenger: Messenger

    var num_voices: Int

    var svf: SVF[]
    var filt_lag: Lag[]
    var filt_freq: Float64
    var bend_mul: Float64

    fn __init__(out self, world: World, num_voices: Int = 8):
        self.world = world
        self.num_voices = num_voices
        self.current_voice = 0

        self.messenger = Messenger(self.world)

        self.voices = List[TrigSynthVoice]()
        for i in range(self.num_voices):
            self.voices.append(TrigSynthVoice(self.world, "voice_"+String(i)))

        self.svf = SVF(self.world)
        self.filt_lag = Lag(self.world, 0.1)
        self.filt_freq = 1000.0
        self.bend_mul = 1.0

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.messenger.update(self.filt_freq, "filt_freq")
        if self.messenger.notify_update(self.bend_mul, "bend_mul"):
            # if bend_mul changes, update all the voices
            for i in range(len(self.voices)):
                self.voices[i].bend_mul = self.bend_mul

        var out = 0.0
        # get the output of all the synths
        for i in range(len(self.voices)):
            out += self.voices[i].next()

        out = self.svf.lpf(out, self.filt_lag.next(self.filt_freq), 2.0) * 0.6

        return out
        

struct MidiSequencer(Representable, Movable, Copyable):
    var world: World

    var output: List[Float64]  # Output buffer for audio samples

    var trig_synth: TrigSynth  # Instance of the Oscillator

    fn __init__(out self, world: World):
        self.world = world
        self.output = [0.0, 0.0]  # Initialize output list

        self.trig_synth = TrigSynth(self.world)  # Initialize the TrigSynth with the world instance

    fn __repr__(self) -> String:
        return String("Midi_Sequencer")

    fn next(mut self: MidiSequencer) -> SIMD[DType.float64, 2]: 
        return self.trig_synth.next()  # Return the combined output sample

