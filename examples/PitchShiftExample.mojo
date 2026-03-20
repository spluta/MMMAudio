from mmm_audio import *

# THE SYNTH

struct PitchShiftExample(Representable, Movable, Copyable):
    var world: World

    var pitch_shift: PitchShift[num_chans=2]
    var messenger: Messenger
    var shift: Float64
    var grain_dur: Float64
    var pitch_dispersion: Float64
    var time_dispersion: Float64
    var in_chan: Int
    var which_input: Float64
    var noise: WhiteNoise[]
    var overlaps: Int
    var added_delay_low: Float64
    var added_delay_high: Float64
    var fb: MFloat[2]
    var fb_perc: Float64
    var dc_trap: DCTrap[2]
     
    fn __init__(out self, world: World):
        self.world = world
        self.pitch_shift = PitchShift[num_chans=2](self.world, 2.0) # the duration of the buffer needs to == grain size*(max_pitch_shift-1).
        self.messenger = Messenger(self.world)
        self.shift = 1.0
        self.grain_dur = 0.2
        self.pitch_dispersion = 0.0
        self.time_dispersion = 0.0
        self.in_chan = 0
        self.which_input = 0.0
        self.noise = WhiteNoise()
        self.overlaps = 4
        self.added_delay_low = 0.0
        self.added_delay_high = 0.0
        self.fb = MFloat[2](0.0, 0.0)
        self.fb_perc = 0.0
        self.dc_trap = DCTrap[2](world)

    @always_inline
    fn next(mut self) -> MFloat[2]:
        self.messenger.update(self.in_chan, "in_chan")

        self.messenger.update(self.shift,"pitch_shift")
        self.messenger.update(self.grain_dur,"grain_dur")
        self.messenger.update(self.pitch_dispersion,"pitch_dispersion")
        self.messenger.update(self.time_dispersion,"time_dispersion")
        self.messenger.update(self.overlaps,"overlaps")
        self.messenger.update(self.added_delay_low,"added_delay_low")
        self.messenger.update(self.added_delay_high,"added_delay_high")
        self.messenger.update(self.fb_perc,"fb_perc")

        temp = self.world[].sound_in[self.in_chan]
        input_sig = MFloat[2](temp, temp) + (self.fb * self.fb_perc)
        
        out = self.pitch_shift.next(input_sig, self.grain_dur, self.overlaps, self.shift, self.pitch_dispersion, self.time_dispersion, self.added_delay_low, self.added_delay_high)
        self.fb = self.dc_trap.next(out)

        return out

    fn __repr__(self) -> String:
        return String("PitchShift")