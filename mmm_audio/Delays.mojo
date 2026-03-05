from mmm_audio import *
from math import tanh
from math import log
from bit import next_power_of_two

struct Delay[num_chans: Int = 1, interp: Int = Interp.linear](Representable, Movable, Copyable):
    """A variable delay line with interpolation.

    Parameters:
      num_chans: Size of the SIMD vector - defaults to 1.
      interp: The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options.
    """

    var world: World
    var max_delay_time: Float64
    var max_delay_samples: Int
    var delay_line: Recorder[Self.num_chans]
    var two_sample_duration: Float64
    var sample_duration: Float64
    var prev_f_idx: List[Float64]

    fn __init__(out self, world: World, max_delay_time: Float64 = 1.0):
      """Initialize the Delay line.

      Args:
        world: A pointer to the MMMWorld.
        max_delay_time: The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay.
      """
        self.world = world
        self.max_delay_time = max_delay_time
        self.max_delay_samples = Int(max_delay_time * self.world[].sample_rate)
        var size_of_buffer = self.max_delay_samples

        @parameter
        if Self.interp == Interp.linear:
          size_of_buffer += 1
        elif Self.interp == Interp.cubic or Self.interp == Interp.quad:
          size_of_buffer += 2
        elif Self.interp == Interp.lagrange4:
          size_of_buffer += 4
        
        self.delay_line = Recorder[Self.num_chans](self.world, size_of_buffer, self.world[].sample_rate)
        self.two_sample_duration = 2.0 / self.world[].sample_rate
        self.sample_duration = 1.0 / self.world[].sample_rate
        self.prev_f_idx = [Self.num_chans, 0.0]

    fn __init__(out self, world: World, max_delay_samples: Int = 1024):
      """Initialize the Delay line.

      Args:
        world: A pointer to the MMMWorld.
        max_delay_samples: The maximum delay time in samples. The internal buffer will be allocated to accommodate this delay.
      """
        self.world = world
        self.max_delay_time = Float64(max_delay_samples) / self.world[].sample_rate
        self.max_delay_samples = max_delay_samples
        var size_of_buffer = self.max_delay_samples
        
        @parameter
        if Self.interp == Interp.linear:
          size_of_buffer += 1
        elif Self.interp == Interp.cubic or Self.interp == Interp.quad:
          size_of_buffer += 2
        elif Self.interp == Interp.lagrange4:
          size_of_buffer += 4

        self.delay_line = Recorder[Self.num_chans](self.world, size_of_buffer, self.world[].sample_rate)
        self.two_sample_duration = 2.0 / self.world[].sample_rate
        self.sample_duration = 1.0 / self.world[].sample_rate
        self.prev_f_idx = [Self.num_chans, 0.0]

    fn __repr__(self) -> String:
        return String("Delay(max_delay_time: " + String(self.max_delay_time) + ")")

    @always_inline
    fn read[N: Int](mut self, var delay_samps: MInt[N]) -> SIMD[DType.float64, self.num_chans]:
      """Reads into the delay line at an exact sample delay and no interpolation.

      Args:
        delay_samps: The amount of delay to apply (in samples).

      Returns:
        A single sample read from the delay buffer with no interpolation. Use a float lookup for fractional delay with interpolation.
      """

      idx = (self.delay_line.write_head + delay_samps) % self.delay_line.buf.num_frames
      @parameter
      if N == 1:
        out = SpanInterpolator.read_none[bWrap=True](self.delay_line.buf.data, Float64(idx[0]))
        return out
      else:
        out = SIMD[DType.float64, Self.num_chans](0.0)
        for chan in range(Self.num_chans):
          out[chan] = SpanInterpolator.read_none[bWrap=True](self.delay_line.buf.data, Float64(idx[chan%N]))[chan]
        return out

    @always_inline
    fn read[N: Int](mut self, var delay_time: MFloat[N]) -> SIMD[DType.float64, self.num_chans]:
      """Reads into the delay line.

      Args:
        delay_time: The amount of delay to apply (in seconds).

      Returns:
        A single sample read from the delay buffer.
      """
      delay_time = min(delay_time, self.max_delay_time)
        
      out = SIMD[DType.float64, self.num_chans](0.0)

      if N == 1:
        @parameter
        if self.interp == Interp.none:
          out = SpanInterpolator.read_none[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[0]))
        elif self.interp == Interp.linear:
          out = SpanInterpolator.read_linear[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[0]))
        elif self.interp == Interp.quad:
          out = SpanInterpolator.read_quad[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[0]))
        elif self.interp == Interp.cubic:
          delay_time = max(delay_time, self.two_sample_duration)
          out = SpanInterpolator.read_cubic[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[0]))
        elif self.interp == Interp.lagrange4:
          out = SpanInterpolator.read_lagrange4[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[0]))
        elif self.interp == Interp.sinc:
          print("Sinc interpolation not recommended for Delays.")
      else:
        for chan in range(Self.num_chans):
          @parameter
          if self.interp == Interp.none:
            out[chan] = SpanInterpolator.read_none[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[chan%N]))[chan]
          elif self.interp == Interp.linear:
            out[chan] = SpanInterpolator.read_linear[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[chan%N]))[chan]
          elif self.interp == Interp.quad:
            out[chan] = SpanInterpolator.read_quad[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[chan%N]))[chan]
          elif self.interp == Interp.cubic:
            out[chan] = SpanInterpolator.read_cubic[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[chan%N]))[chan]
          elif self.interp == Interp.lagrange4:
            out[chan] = SpanInterpolator.read_lagrange4[bWrap=True](self.delay_line.buf.data, self.get_f_idx(delay_time[chan%N]))[chan]
          elif self.interp == Interp.sinc:
            print("Sinc interpolation not recommended for Delays.")
      return out

    @always_inline
    fn write(mut self, input: SIMD[DType.float64, self.num_chans]):
      """Writes a single sampleinto the delay line."""

        self.delay_line.write_previous(input)

    @always_inline
    fn next[N: Int](mut self, input: SIMD[DType.float64, self.num_chans], delay_samps: MInt[N]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the delay line, first reading from the delay then writing into it. This version uses an integer lookup into the delay line and no interpolation.

        Args:
          input: The input sample to process.
          delay_samps: The amount of delay to apply (in samples).

        Returns:
          The processed output sample.
        """
        
        out = self.read(delay_samps)
        self.write(input)

        return out

    @always_inline
    fn next[N: Int](mut self, input: SIMD[DType.float64, self.num_chans], var delay_time: MFloat[N]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the delay line, first reading from the delay then writing into it.

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).

        Returns:
          The processed output sample.
        """
        
        out = self.read(delay_time)
        self.write(input)

        return out

    @always_inline
    fn get_f_idx(self, delay_time: Float64) -> Float64:
        """Calculate the fractional index in the delay buffer for the given delay time.

        Args:
          delay_time: The delay time in seconds.

        Returns:
          The fractional index in the delay buffer.
        """

        delay_samps = max(delay_time, self.sample_duration) * self.world[].sample_rate
        # Because the SpanInterpolator functions always "read" forward,
        # we're writing into the delay line buffer backwards, so therefore,
        # here to go backwards in time we add the delay samples to the write head.
        f_idx = (Float64(self.delay_line.write_head) + delay_samps) % Float64(self.delay_line.buf.num_frames)
        return f_idx

fn calc_feedback[num_chans: Int = 1](delaytime: SIMD[DType.float64, num_chans], decaytime: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
      """Calculate the feedback coefficient for a Comb filter or Allpass line based on desired delay time and decay time.
      
      Parameters:
        num_chans: Size of the SIMD vector - defaults to 1.

      Args:
        delaytime: The delay time in seconds.
        decaytime: The decay time in seconds (time to -60dB)."""
      
      comptime log001: Float64 = log(0.001)

      zero: SIMD[DType.bool, num_chans] = delaytime.eq(0) or decaytime.eq(0)
      dec_pos: SIMD[DType.bool, num_chans] = decaytime.ge(0)

      absret = exp(log001 * delaytime / abs(decaytime))

      return zero.select(SIMD[DType.float64, num_chans](0.0), dec_pos.select(absret, -absret))

struct Comb[num_chans: Int = 1, interp: Int = 2](Movable, Copyable):
    """
    A simple comb filter using a delay line with feedback.

    Parameters:
      num_chans: Size of the SIMD vector.
      interp: The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options.

    """

    var world: World
    var delay: Delay[Self.num_chans, Self.interp]
    var fb: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self, world: World, max_delay: Float64 = 1.0):
      """Initialize the Comb filter.

      Args:
        world: A pointer to the MMMWorld.
        max_delay: The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay.
      """
        self.world = world
        self.delay = Delay[Self.num_chans, Self.interp](self.world, max_delay)
        self.fb = SIMD[DType.float64, Self.num_chans](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans] = 0.0, feedback: SIMD[DType.float64, self.num_chans] = 0.0) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the comb filter.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (-1.0 to 1.0).

        Returns:
          The delayed output sample.
        """
        # Get the delayed sample
        fb_in = input + self.fb * clip(feedback, -1.0, 1.0)
        var out = self.delay.next(fb_in, delay_time)  

        self.fb = out

        return out  # Return the delayed sample

    fn next_decaytime(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans], decay_time: SIMD[DType.float64, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the comb filter with decay time calculation.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          decay_time: The desired decay time (time to -60dB). Feedback is calculated internally.

        Returns:
          The delayed output sample.
        """
        feedback = calc_feedback(delay_time, decay_time)
        return self.next(input, delay_time, feedback)

struct LP_Comb[num_chans: Int = 1, interp: Int = Interp.linear](Movable, Copyable):
    """
    A simple comb filter with an integrated one-pole low-pass filter.
    
    Parameters:
      num_chans: Size of the SIMD vector - defaults to 1.
      interp: The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options.
    """
    var world: World
    var delay: Delay[Self.num_chans, Self.interp] # Delay line without automatic feedback
    var one_pole: OnePole[Self.num_chans]
    var fb: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self, world: World, max_delay: Float64 = 1.0):
      """Initialize the LP_Comb filter.

      Args:
        world: A pointer to the MMMWorld.
        max_delay: The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay.
      """ 

        self.world = world
        self.delay = Delay[Self.num_chans, Self.interp](self.world, max_delay)
        self.one_pole = OnePole[Self.num_chans](self.world)
        self.fb = SIMD[DType.float64, Self.num_chans](0.0)

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, Self.num_chans], delay_time: SIMD[DType.float64, Self.num_chans] = 0.0, feedback: SIMD[DType.float64, Self.num_chans] = 0.0, lp_freq: SIMD[DType.float64, Self.num_chans] = 0.0) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the comb filter.

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (-1.0 to 1.0).
          lp_freq: The cutoff frequency of the OnePole filter in the feedback loop.

        Returns:
          The processed output sample.
        """
        fb_in = input + self.fb * clip(feedback, -1.0, 1.0)
        var out = self.delay.next(fb_in, delay_time)

        self.fb = self.one_pole.lpf(out, lp_freq)  # Low-pass filter the feedback

        return out

    fn __repr__(self) -> String:
        return "LP_Comb"

struct Allpass_Comb[num_chans: Int = 1, interp: Int = Interp.linear](Movable, Copyable):
    """
    A simple allpass comb filter using a delay line with feedback.
    
    Parameters:
      num_chans: Size of the SIMD vector.
      interp: The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options.
    """
    var world: World
    var delay: Delay[Self.num_chans, Self.interp]

    fn __init__(out self, world: World, max_delay: Float64 = 1.0):
      """Initialize the Allpass Comb filter.

      Args:
        world: A pointer to the MMMWorld.
        max_delay: The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay.
      """

        self.world = world
        self.delay = Delay[Self.num_chans, Self.interp](self.world, max_delay)

    fn next(mut self, input: SIMD[DType.float64, Self.num_chans], delay_time: SIMD[DType.float64, Self.num_chans] = 0.0, feedback_coef: SIMD[DType.float64, Self.num_chans] = 0.0) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the allpass comb filter.

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback_coef: The feedback coefficient (-1.0 to 1.0).

        Returns:
          The delayed/filtered output sample.
        """

        var delayed = self.delay.read(delay_time)
        var to_delay = input + feedback_coef * delayed
        var output = (-feedback_coef * input) + delayed
        
        self.delay.write(to_delay)
        
        return output

    fn next_decaytime(mut self, input: SIMD[DType.float64, self.num_chans], delay_time: SIMD[DType.float64, self.num_chans], decay_time: SIMD[DType.float64, self.num_chans]) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the allpass comb filter with decay time calculation.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          decay_time: The desired decay time (time to -60dB).
        
        """
        feedback = calc_feedback(delay_time, decay_time)
        return self.next(input, delay_time, feedback)
    

struct FB_Delay[num_chans: Int = 1, interp: Int = Interp.lagrange4, ADAA_dist: Bool = False, os_index: Int = 0](Representable, Movable, Copyable):
    """A feedback delay structured like a Comb filter, but with possible feedback coefficient above 1 due to an integrated tanh function.
    
    By default, Anti-comptimeing is disabled and no [oversampling](Oversampling.md) is applied, but this can be changed by setting the ADAA_dist and os_index template parameters.
    
    Parameters:
      num_chans: Size of the SIMD vector.
      interp: The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options.
      ADAA_dist: Whether to apply ADAA distortion to the feedback signal instead of standard tanh.
      os_index: The [oversampling](Oversampling.md) index for ADAA distortion. 0 = no oversampling, 1 = 2x, 2 = 4x, 3 = 8x, 4 = 16x.
    """

    var world: World
    var delay: Delay[Self.num_chans, Self.interp]
    var dc: DCTrap[Self.num_chans]
    var fb: SIMD[DType.float64, Self.num_chans]
    var tanh_ad: TanhAD[Self.num_chans, Self.os_index]

    fn __init__(out self, world: World, max_delay: Float64 = 1.0):
      """Initialize the FB_Delay.

      Args:
        world: A pointer to the MMMWorld.
        max_delay: The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay.
      """

        self.world = world
        self.delay = Delay[Self.num_chans, Self.interp](self.world, max_delay)
        self.dc = DCTrap[Self.num_chans](self.world)
        self.fb = SIMD[DType.float64, Self.num_chans](0.0)
        self.tanh_ad = TanhAD[Self.num_chans, Self.os_index](self.world)

    fn next(mut self, input: SIMD[DType.float64, Self.num_chans], delay_time: SIMD[DType.float64, Self.num_chans], feedback: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample or SIMD vector through the feedback delay.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).

        Returns:
          The processed output sample or SIMD vector.
        """
        var out = self.delay.next(self.fb, delay_time)  # Get the delayed sample

        @parameter
        if Self.ADAA_dist:
            self.fb = self.dc.next(self.tanh_ad.next((input + out) * feedback))
        else:
          self.fb = self.dc.next(tanh((input + out) * feedback))

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "FB_Delay"
