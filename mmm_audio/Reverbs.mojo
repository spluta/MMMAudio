from mmm_audio import *
from math import tanh
from algorithm import vectorize
from sys import simd_width_of


struct Freeverb[num_chans: Int = 1](Representable, Movable, Copyable):
    """
    A custom implementation of the Freeverb reverb algorithm. Based on Romain Michon's Faust implementation (https://github.com/grame-cncm/faustlibraries/blob/master/reverbs.lib), thus is licensed under LGPL.

    Parameters:
      num_chans: Size of the SIMD vector - defaults to 1.
    """
    var world: World
    var lp_comb0: LP_Comb[Self.num_chans]
    var lp_comb1: LP_Comb[Self.num_chans]
    var lp_comb2: LP_Comb[Self.num_chans]
    var lp_comb3: LP_Comb[Self.num_chans]
    var lp_comb4: LP_Comb[Self.num_chans]
    var lp_comb5: LP_Comb[Self.num_chans]
    var lp_comb6: LP_Comb[Self.num_chans]
    var lp_comb7: LP_Comb[Self.num_chans]

    var temp: List[Float64]
    var allpass_combs: List[Allpass_Comb[Self.num_chans]]
    var feedback: List[Float64]
    var lp_comb_lpfreq: List[Float64]
    var in_list: List[Float64]

    fn __init__(out self, world: World):
      """
      Initialize the Freeverb struct.

      Args:
          world: A pointer to the MMMWorld instance.
      """
      
        self.world = world
        
        # I tried doing this with lists of LP_Comb[N] but avoiding lists seems to work better in Mojo currently

        self.lp_comb0 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb1 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb2 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb3 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb4 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb5 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb6 = LP_Comb[Self.num_chans](self.world, 0.04)
        self.lp_comb7 = LP_Comb[Self.num_chans](self.world, 0.04)

        self.temp = [0.0 for _ in range(8)]
        self.allpass_combs = [Allpass_Comb[Self.num_chans](self.world, 0.015) for _ in range(4)]
        
        self.feedback = [0.0]
        self.lp_comb_lpfreq = [1000.0]
        self.in_list = [0.0]

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, self.num_chans], room_size: SIMD[DType.float64, self.num_chans] = 0.0, lp_comb_lpfreq: SIMD[DType.float64, self.num_chans] = 1000.0, added_space: SIMD[DType.float64, self.num_chans] = 0.0) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the freeverb.

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
        feedback2 = 0.5

        delay_offset = added_space_clipped * 0.0012

        out = self.lp_comb0.next(input, 0.025306122448979593 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb1.next(input, 0.026938775510204082 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb2.next(input, 0.02895691609977324 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb3.next(input, 0.03074829931972789 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb4.next(input, 0.03224489795918367 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb5.next(input, 0.03380952380952381 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb6.next(input, 0.03530612244897959 + delay_offset, feedback, lp_comb_lpfreq)
        out += self.lp_comb7.next(input, 0.03666666666666667 + delay_offset, feedback, lp_comb_lpfreq)

        out = self.allpass_combs[0].next(out, 0.012607709750566893, feedback2)
        out = self.allpass_combs[1].next(out, 0.01, feedback2)
        out = self.allpass_combs[2].next(out, 0.007732426303854875, feedback2)
        out = self.allpass_combs[3].next(out, 0.00510204081632653, feedback2)

        out = sanitize(out)

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "LP_Comb"