from mmm_audio import *

# THE SYNTH

struct PitchShiftExample(Representable, Movable, Copyable):
    var world: World

    var pitch_shift: PitchShift[num_chans=2, overlaps=4]
    var messenger: Messenger
    var shift: Float64
    var grain_dur: Float64
    var pitch_dispersion: Float64
    var time_dispersion: Float64
    var in_chan: Int
    var which_input: Float64
    var noise: WhiteNoise[]
     
    fn __init__(out self, world: World):
        self.world = world
        self.pitch_shift = PitchShift[num_chans=2, overlaps=4](self.world, 1.0) # the duration of the buffer needs to == grain size*(max_pitch_shift-1).
        self.messenger = Messenger(self.world)
        self.shift = 1.0
        self.grain_dur = 0.2
        self.pitch_dispersion = 0.0
        self.time_dispersion = 0.0
        self.in_chan = 0
        self.which_input = 0.0
        self.noise = WhiteNoise()

    @always_inline
    fn next(mut self) -> MFloat[2]:
        self.messenger.update(self.which_input, "which_input")
        self.messenger.update(self.in_chan, "in_chan")

        temp = self.world[].sound_in[self.in_chan]
        input_sig = select(self.which_input, [MFloat[2](temp, temp), MFloat[2](temp, 0.0), MFloat[2](0.0, temp)])
        
        self.messenger.update(self.shift,"pitch_shift")
        self.messenger.update(self.grain_dur,"grain_dur")
        self.messenger.update(self.pitch_dispersion,"pitch_dispersion")
        self.messenger.update(self.time_dispersion,"time_dispersion")

        # shift = linexp(self.world[].mouse_y, 0.0, 1.0, 0.25, 4.0)
        # grain_dur = linexp(self.world[].mouse_x, 0.0, 1.0, 0.05, 0.3)
        out = self.pitch_shift.next(input_sig, self.grain_dur, self.shift, self.pitch_dispersion, self.time_dispersion)

        return out

    fn __repr__(self) -> String:
        return String("PitchShift")