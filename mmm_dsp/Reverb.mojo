from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *
from mmm_dsp.Delays import *
from algorithm import vectorize
from sys import simd_width_of


struct Freeverb[N: Int = 1](Representable, Movable, Copyable):
    """
    A custom implementation of the Freeverb reverb algorithm. Based on Romain Michon's Faust implementation (https://github.com/grame-cncm/faustlibraries/blob/master/reverbs.lib), thus is licensed under LGPL.
    
    ``Freeverb[N](world_ptr)``

    Parameters:
      N: size of the SIMD vector - defaults to 1
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var lp_combs: List[LP_CombN[8]]
    var del_times: List[Float64]
    var del_timesB: List[Float64]
    var temp: List[Float64]
    var allpass_combs: List[Allpass_Comb[N]]
    var allpass_del_times: List[Float64]
    var feedback: List[Float64]
    var lp_comb_lpfreq: List[Float64]
    var in_list: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.lp_combs = [ LP_CombN[8](self.world_ptr) for _ in range(self.N)]
        self.del_times = [1116.0 / 44100.0, 1188.0 / 44100.0, 1277.0 / 44100.0, 1356.0 / 44100.0, 1422.0 / 44100.0, 1491.0 / 44100.0, 1557.0 / 44100.0, 1617.0 / 44100.0] # in seconds
        self.del_timesB = [0.0 for _ in range(8)] # in seconds

        self.temp = [0.0 for _ in range(8)]
        self.allpass_combs = [Allpass_Comb[N](self.world_ptr, 0.02) for _ in range(4)]
        self.allpass_del_times = [556.0 / 44100.0, 441.0 / 44100.0, 341.0 / 44100.0, 225.0 / 44100.0]
        self.feedback = [0.0]
        self.lp_comb_lpfreq = [1000.0]
        self.in_list = [0.0]

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, self.N], room_size: SIMD[DType.float64, self.N] = 0.0, lp_comb_lpfreq: SIMD[DType.float64, self.N] = 1000.0, added_space: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
        """
        Process one sample through the freeverb.
        
        next(input, delay_time=0.0, feedback=0.0, interp=0)

        Args:
          input: The input sample to process.
          room_size: The size of the reverb room (0-1).
          lp_comb_lpfreq: The cutoff frequency of the low-pass filter (in Hz).
          added_space: The amount of added space (0-1).

        Returns:
          The processed output sample.

        """
        out = SIMD[DType.float64, self.N](0.0)
        room_size_clipped = clip(room_size, 0.0, 1.0)
        added_space_clipped = clip(added_space, 0.0, 1.0)
        feedback = 0.28 + (room_size_clipped * 0.7)

        delay_offset = added_space_clipped * 0.0012

        @parameter
        for i in range(self.N):
          @parameter
          for j in range(8):
              self.del_timesB[j] = self.del_times[j] + delay_offset[i]
          self.feedback[0] = feedback[i]
          self.lp_comb_lpfreq[0] = lp_comb_lpfreq[i]

          self.in_list[0] = input[i]
          self.lp_combs[i].next(self.in_list, self.temp, self.del_timesB, self.feedback, self.lp_comb_lpfreq)
          out[i] = 0.0
          @parameter
          for j in range(8):
              out[i] += self.temp[j]
        @parameter
        for j in range(4):
            out = self.allpass_combs[j].next(out, self.allpass_del_times[j])

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "LP_Comb"