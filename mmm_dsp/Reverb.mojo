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
    # var lp_combs: List[LP_CombN[8]]
    var lp_comb0: LP_Comb[N]
    var lp_comb1: LP_Comb[N]
    var lp_comb2: LP_Comb[N]
    var lp_comb3: LP_Comb[N]
    var lp_comb4: LP_Comb[N]
    var lp_comb5: LP_Comb[N]
    var lp_comb6: LP_Comb[N]
    var lp_comb7: LP_Comb[N]

    var temp: List[Float64]
    var allpass_combs: List[Allpass_Comb[N]]
    var feedback: List[Float64]
    var lp_comb_lpfreq: List[Float64]
    var in_list: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        
        # I tried doing this with lists of LP_Comb[N] but avoiding lists seems to work better in Mojo currently

        self.lp_comb0 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb1 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb2 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb3 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb4 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb5 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb6 = LP_Comb[N](self.world_ptr, 0.04)
        self.lp_comb7 = LP_Comb[N](self.world_ptr, 0.04)

        self.temp = [0.0 for _ in range(8)]
        self.allpass_combs = [Allpass_Comb[N](self.world_ptr, 0.015) for _ in range(4)]
        
        self.feedback = [0.0]
        self.lp_comb_lpfreq = [1000.0]
        self.in_list = [0.0]

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, self.N], room_size: SIMD[DType.float64, self.N] = 0.0, lp_comb_lpfreq: SIMD[DType.float64, self.N] = 1000.0, added_space: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
        """
        Process one sample through the freeverb.
        
        next(input, room_size=0.0, lp_comb_lpfreq=1000.0, added_space=0.0) -> Float64

        Args:
          input: The input sample to process.
          room_size: The size of the reverb room (0-1).
          lp_comb_lpfreq: The cutoff frequency of the low-pass filter (in Hz).
          added_space: The amount of added space (0-1).

        Returns:
          The processed output sample.

        """
        room_size_clipped = clip(room_size, 0.0, 1.0)
        added_space_clipped = clip(added_space, 0.0, 1.0)
        feedback = 0.28 + (room_size_clipped * 0.7)

        delay_offset = added_space_clipped * 0.0012

        out = self.lp_comb0.next(input, 0.025306122448979593 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb1.next(input, 0.026938775510204082 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb2.next(input, 0.02895691609977324 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb3.next(input, 0.03074829931972789 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb4.next(input, 0.03224489795918367 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb5.next(input, 0.03380952380952381 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb6.next(input, 0.03530612244897959 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb7.next(input, 0.03666666666666667 + delay_offset, feedback, lp_comb_lpfreq)

        out = self.allpass_combs[0].next(out, 0.012607709750566893)
        out = self.allpass_combs[1].next(out, 0.01)
        out = self.allpass_combs[2].next(out, 0.007732426303854875)
        out = self.allpass_combs[3].next(out, 0.00510204081632653)


        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "LP_Comb"