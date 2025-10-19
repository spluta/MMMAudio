from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_utils.functions import linexp
from random import random_float64
from mmm_utils.Messengers import Messenger

# THE SYNTH

struct PitchShiftExample(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var pitch_shift: PitchShift
    var messenger: Messenger
     
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.pitch_shift = PitchShift(world_ptr, 1.0) # the duration of the buffer needs to == grain size*(max_pitch_shift-1).
        self.messenger = Messenger(world_ptr)

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        input_sig = self.world_ptr[0].sound_in[8]
        shift = self.messenger.get_val("pitch_shift", 1.0)
        grain_size = self.messenger.get_val("grain_size", 0.2)
        pitch_dispersion = self.messenger.get_val("pitch_dispersion", 0.0)
        time_dispersion = self.messenger.get_val("time_dispersion", 0.0)

        # shift = linexp(self.world_ptr[0].mouse_y, 0.0, 1.0, 0.25, 4.0)
        # grain_size = linexp(self.world_ptr[0].mouse_x, 0.0, 1.0, 0.05, 0.3)
        out = self.pitch_shift.next(input_sig, grain_size, shift, pitch_dispersion, time_dispersion)

        return out

    fn __repr__(self) -> String:
        return String("PitchShift")