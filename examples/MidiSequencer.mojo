from mmm_audio import *

# Synth Voice - Below is a polyphonic synth. The first struct, TrigSynthVoice, is a single voice of the synth. Each voice is made up of a modulator oscillator, a carrier oscillator, and an envelope generator. 

# TrigSynthVoice follows the pattern of a triggerd PolyObject - it has a set_trigger function that Poly calls to trigger the voice.

struct TrigSynthVoice(PolyObject):
    var world: World  # Pointer to the MMMWorld instance
    var env: Env
    var mod: Osc[]
    var car: Osc[1, Interp.linear, 0]
    var sub: Osc[]
    var bend_mul: Float64
    var note: List[Float64]
    var trigger: Bool

    fn check_active(mut self) -> Bool:
        return self.env.is_active


    # Poly will use this function to trigger the voice.
    fn set_trigger(mut self, trigger: Bool):
        self.trigger = trigger

    fn __init__(out self, world: World):
        self.world = world
        self.mod = Osc(self.world)
        self.car = Osc[1, Interp.linear, 0](self.world)
        self.sub = Osc(self.world)
        self.env = Env(self.world)
        self.env.params = EnvParams([0.0, 1.0, 0.75, 0.75, 0.0], [0.01, 0.1, 0.2, 0.5], [1.0])
        self.bend_mul = 1.0
        self.note = List[Float64]()
        self.trigger = False

    @always_inline
    fn next(mut self) -> Float64:
        # if there is no trigger and the envelope is not active, that means the voice should be silent - output 0.0
        if not self.env.is_active and not self.trigger:
            return 0.0
        else:
            bend_freq = self.note[0] * self.bend_mul
            var mod_value = self.mod.next(bend_freq * 1.5, osc_type=OscType.sine)  
            var env = self.env.next(self.trigger)  
            var mod_mult = env * 0.5 * linlin(bend_freq, 1000, 4000, 1, 0) #decrease the mod amount as freq increases
            var car_value = self.car.next(bend_freq, mod_value * mod_mult, osc_type=OscType.sine)  

            car_value += self.sub.next(bend_freq * 0.5) 
            car_value = car_value * 0.1 * env * self.note[1]  

            return car_value

    # if you want to use this voice without Poly
    fn next(mut self, trigger: Bool) -> Float64:
        self.set_trigger(trigger)
        out = self.next()
        return out


struct MidiSequencer(Movable, Copyable):
    comptime num_messages = 10

    var world: World 
    var voices: List[TrigSynthVoice]
    var current_voice: Int
    var messenger: Messenger
    var num_voices: Int
    var svf: SVF[]
    var filt_lag: Lag[]
    var filt_freq: Float64
    var bend_mul: Float64
    var poly: Poly[]

    fn __init__(out self, world: World, num_voices: Int = 8):
        self.world = world
        self.num_voices = num_voices
        self.current_voice = 0

        self.messenger = Messenger(self.world)

        self.voices = [TrigSynthVoice(self.world) for _ in range(num_voices)]  # Initialize the list of voices

        self.svf = SVF(self.world)
        self.filt_lag = Lag(self.world, 0.1)
        self.filt_freq = 1000.0
        self.bend_mul = 1.0
        self.poly = Poly(initial_num_voices=num_voices, max_voices=64, world=world)

    @always_inline
    fn next(mut self) -> MFloat[2]:
        var out = 0.0
        self.poly.reset(self.voices) # reset poly at the top of each block - only necessary if multiple voices can be triggered at once.
        # can receive up to num_messages each audio block
        for i in range(Self.num_messages):
            note = [0.0, 0.0]
            trig = self.messenger.notify_update(note, "note"+String(i))

            # if we received a trig, find and play a free voice
            if trig:
                free_voice = self.poly.find_voice_and_trigger(self.voices, trig) # get the index of the free voice and trigger the PolyObject
                self.voices[free_voice].note = note^

        # add the values of the voices that are not being triggered 
        for i in range(len(self.voices)):
            out += self.voices[i].next()

        self.messenger.update(self.filt_freq, "filt_freq")
        if self.messenger.notify_update(self.bend_mul, "bend_mul"):
            # if bend_mul changes, update all the voices
            for i in range(len(self.voices)):
                self.voices[i].bend_mul = self.bend_mul

        out = self.svf.lpf(out, self.filt_lag.next(self.filt_freq), 2.0) * 0.6

        return out
        

