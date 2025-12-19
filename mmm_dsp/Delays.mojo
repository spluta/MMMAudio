from mmm_src.MMMWorld import *
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *
from mmm_dsp.Filters import VAOnePole, DCTrap
from math import log
from mmm_dsp.Recorder import Recorder
from bit import next_power_of_two

struct Delay[num_chans: Int = 1, interp: Int = Interp.linear](Representable, Movable, Copyable):
    """A variable delay line with interpolation.

    Parameters:
      num_chans: Size of the SIMD vector - defaults to 1.
      interp: The interpolation method to use (0 = no interpolation, 1 = linear, 2 = cubic, 3 = Lagrange). See `struct Interp` for how you can specify the desired interpolation method with words rather than integers.

    Args:
      w: Pointer to the MMMWorld instance.
      max_delay: The maximum delay time in seconds.
    """

    var w: UnsafePointer[MMMWorld]
    var max_delay_time: Float64
    var max_delay_samples: Int64
    var buffer_length_samples: Int64
    var wrap_mask: Int64
    var delay_line: Recorder[num_chans]
    var two_sample_duration: Float64
    var sample_duration: Float64

    def __init__(out self, w: UnsafePointer[MMMWorld], max_delay_time: Float64 = 1.0):
        self.w = w
        self.max_delay_time = max_delay_time
        self.max_delay_samples = Int64(max_delay_time * self.w[].sample_rate) + 1
        self.buffer_length_samples = next_power_of_two(self.max_delay_samples)
        self.wrap_mask = self.buffer_length_samples - 1
        self.delay_line = Recorder[num_chans](self.w, self.buffer_length_samples, self.w[].sample_rate)
        self.two_sample_duration = 2.0 / self.w[].sample_rate
        self.sample_duration = 1.0 / self.w[].sample_rate

    fn __repr__(self) -> String:
        return String("Delay(max_delay_time: " + String(self.max_delay_time) + ")")

    fn next(mut self, input: SIMD[DType.float64, self.num_chans], var delay_time: SIMD[DType.float64, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the delay line.
        This function computes the average of two values.

        next(input, delay_time)
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).

        Returns:
          The processed output sample.

        """
        self.delay_line.write_previous(input)

        delay_time = min(delay_time, self.max_delay_time)
        
        # minimum delay time depends on interpolation method
        @parameter
        if interp == Interp.none:
          delay_time = max(delay_time, 0.0)
          return ListInterpolator.read_none[bWrap=True](self.delay_line.buf.data, self.write_idx, delay_time * self.w[].sample_rate)
        elif interp == Interp.linear:
          delay_time = max(delay_time, 0.0)
          return self.linear_loc(input, delay_time)
        elif interp == Interp.cubic:
          delay_time = max(delay_time, self.two_sample_duration)
          return self.cubic_loc(input, delay_time)
        elif interp == Interp.lagrange4:
          delay_time = max(delay_time, 0.0)
          return self.lagrange4(input, delay_time)
        else: 
          delay_time = max(delay_time, 0.0)
          return self.none(input, delay_time)


fn calc_feedback[N: Int = 1](delaytime: SIMD[DType.float64, N], decaytime: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
      alias log001: Float64 = log(0.001)

      zero: SIMD[DType.bool, N] = delaytime.eq(0) or decaytime.eq(0)
      dec_pos: SIMD[DType.bool, N] = decaytime.ge(0)

      absret = exp(log001 * delaytime / abs(decaytime))

      return zero.select(SIMD[DType.float64, N](0.0), dec_pos.select(absret, -absret))

struct Comb[N: Int = 1, interp: Int = 2](Movable, Copyable):
    """
    A simple comb filter using a delay line with feedback.
    
    """

    var w: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, w: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.w = w
        self.delay = Delay[N, interp](self.w, max_delay)
        self.fb = SIMD[DType.float64, N](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans] = 0.0, feedback: SIMD[DType.float64, self.num_chans] = 0.0) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the comb filter.
        
        next(input, delay_time=0.0, feedback=0.0)

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).

        Returns:
          The processed output sample.

        """
        # Get the delayed sample
        # does not write to the buffer
        var out = self.delay.next(self.fb, delay_time)  
        temp = input + out * clip(feedback, 0.0, 1.0)  # Apply feedback

        self.fb = temp

        return out  # Return the delayed sample

    fn next_decaytime(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans], decay_time: SIMD[DType.float64, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the comb filter with decay time calculation."""
        feedback = calc_feedback(delay_time, decay_time)
        return self.next(input, delay_time, feedback)

struct LP_Comb[N: Int = 1, interp: Int = 0](Movable, Copyable):
    """
    A simple comb filter with an integrated one-pole low-pass filter.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1
      interp: The interpolation method to use (0 = linear, 2 = Lagrange).

    Args:
      w: Pointer to the MMMWorld instance.

      max_delay: The maximum delay time in seconds.
    """
    var w: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp] # Delay line without automatic feedback
    var one_pole: VAOnePole[N]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, w: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.w = w
        self.delay = Delay[N, interp](self.w, max_delay)
        self.one_pole = VAOnePole[N](w)
        self.fb = SIMD[DType.float64, N](0.0)

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans] = 0.0, feedback: SIMD[DType.float64, self.num_chans] = 0.0, lp_freq: SIMD[DType.float64, self.num_chans] = 0.0) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the comb filter.
        
        next(input, delay_time=0.0, feedback=0.0)

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).
          lp_freq: The cutoff frequency of the VAOnePole filter in the feedback loop.

        Returns:
          The processed output sample.

        """
        var out = self.delay.next(self.fb, delay_time)  # Get the delayed sample

        self.fb = self.one_pole.lpf(out * clip(feedback, 0.0, 1.0), lp_freq)  # Low-pass filter the feedback

        self.fb += input

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "LP_Comb"

struct Allpass_Comb[N: Int = 1, interp: Int = Interp.lagrange](Movable, Copyable):
    """
    A simple all-pass comb filter using a delay line with feedback.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1

    Args:
      w: Pointer to the MMMWorld instance.
      max_delay: The maximum delay time in seconds.
    """
    var w: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp]
    var allpass_feedback: SIMD[DType.float64, N]
    var last_delay: SIMD[DType.float64, N]

    fn __init__(out self, w: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.w = w
        self.delay = Delay[N, interp](self.w, max_delay)
        self.allpass_feedback = 0.0
        self.last_delay = SIMD[DType.float64, self.num_chans](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans] = 0.0, feedback_coef: SIMD[DType.float64, self.num_chans] = 0.0) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the all-pass comb filter

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
        Returns:
          The processed output sample.
        """
        
        temp = self.allpass_feedback + input
        temp2 = self.delay.next(temp, delay_time)  # Get the delayed sample and write to the delay line
        self.allpass_feedback = (temp2 * (feedback_coef))

        out2 = temp * -feedback_coef + self.last_delay
        self.last_delay = temp2

        return out2

    fn next_decaytime(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans], decay_time: SIMD[DType.float64, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the all-pass comb filter with decay time calculation."""
        feedback = calc_feedback(delay_time, decay_time)
        return self.next(input, delay_time, feedback)

struct FB_Delay[N: Int = 1, interp: Int = 3](Representable, Movable, Copyable):
    """Like a Comb filter but with any amount of feedback and a tanh function."""

    var w: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp]
    var dc: DCTrap[N]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, w: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.w = w
        self.delay = Delay[N, interp](self.w, max_delay)
        self.dc = DCTrap[N](w)
        self.fb = SIMD[DType.float64, N](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans], feedback: SIMD[DType.float64, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample or SIMD vector through the feedback delay.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).

        Returns:
          The processed output sample or SIMD vector.

        """
        var out = self.delay.next(self.fb, delay_time)  # Get the delayed sample

        self.fb = self.dc.next(tanh((input + out) * feedback))

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "FB_Delay"
