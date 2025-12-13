from mmm_src.MMMWorld import *
from mmm_utils.functions import *

from mmm_dsp.Play import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_utils.functions import linexp
from random import random_float64
from mmm_utils.Messenger import Messenger

# THE SYNTH

struct PitchShiftExample(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]

    var pitch_shift: PitchShift
    var messenger: Messenger
    var shift: Float64
    var grain_size: Float64
    var pitch_dispersion: Float64
    var time_dispersion: Float64
     
    def __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.pitch_shift = PitchShift(w, 1.0) # the duration of the buffer needs to == grain size*(max_pitch_shift-1).
        self.messenger = Messenger(w)
        self.shift = 1.0
        self.grain_size = 0.2
        self.pitch_dispersion = 0.0
        self.time_dispersion = 0.0

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        input_sig = self.w[].sound_in[0]
        self.messenger.update(self.shift,"pitch_shift")
        self.messenger.update(self.grain_size,"grain_size")
        self.messenger.update(self.pitch_dispersion,"pitch_dispersion")
        self.messenger.update(self.time_dispersion,"time_dispersion")

        # shift = linexp(self.w[].mouse_y, 0.0, 1.0, 0.25, 4.0)
        # grain_size = linexp(self.w[].mouse_x, 0.0, 1.0, 0.05, 0.3)
        out = self.pitch_shift.next(input_sig, self.grain_size, self.shift, self.pitch_dispersion, self.time_dispersion)

        return out

    fn __repr__(self) -> String:
        return String("PitchShift")