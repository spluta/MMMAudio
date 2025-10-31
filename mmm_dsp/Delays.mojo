from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *
from sys import simd_width_of
from algorithm import vectorize
from mmm_dsp.Filters import VAOnePole, DCTrap

alias simd_width = simd_width_of[DType.float64]()*2

struct DelayInterpOptions:
    """
    Interpolation options. When passed as an argument it is *actually* an integer, 
    so this struct provides a convenient way to not need to memorize those which integer
    corresponds to which interpolation method. The options are:
    
    - `.none` (0): No interpolation, simply read the nearest sample from the delay line.
    - `.linear` (1): Linear interpolation between the two nearest samples.
    - `.cubic` (2): Cubic interpolation using the four nearest samples.
    - `.lagrange4` (3): Lagrange interpolation using the four nearest samples.
    """
    alias none: Int = 0
    alias linear: Int = 1
    alias cubic: Int = 2
    alias lagrange: Int = 3

struct Delay[N: Int = 1, interp: Int = 3](Representable, Movable, Copyable):
    """
    A variable delay line with Lagrange interpolation.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1
      interp: The interpolation method to use (0 = no interpolation, 1 = linear, 2 = cubic, 3 = Lagrange). See `struct DelayInterpOptions` for how you can specify the desired interpolation method with words rather than integers.
      write_to_buffer: Whether to write the input sample to the delay buffer (True by default). If False, the delay line will not be updated with new samples. (This is useful for implementing feedback delays like comb filters where you want to control when samples are written to the delay line.)


    Args:
      world_ptr: Pointer to the MMMWorld instance.
      max_delay: The maximum delay time in seconds.
    """

    var world_ptr: UnsafePointer[MMMWorld]
    var max_delay_time: Float64
    var max_delay_samples: Int64
    var delay_line: List[List[Float64]]
    var write_idx: Int64
    var two_sample_duration: Float64
    var sample_duration: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay_time: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.max_delay_time = max_delay_time
        self.max_delay_samples = Int64(max_delay_time * self.world_ptr[0].sample_rate) + 1
        self.delay_line = [[Float64(0.0) for _ in range(self.max_delay_samples)] for _ in range(N)]
        self.write_idx = 0
        self.two_sample_duration = 2.0 / self.world_ptr[0].sample_rate
        self.sample_duration = 1.0 / self.world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String("Delay(max_delay_time: " + String(self.max_delay_time) + ")")

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process one sample through the delay line.
        This function computes the average of two values.

        next(input, delay_time)
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).

        Returns:
          The processed output sample.

        """
        self.write_idx = (self.write_idx + 1) % self.max_delay_samples
        # Write the input sample to the delay line
        @parameter
        for i in range(self.N):
            self.delay_line[i][self.write_idx] = input[i]

        delay_time2 = min(delay_time, self.max_delay_time)
        
        # minimum delay time depends on interpolation method
        @parameter
        if interp == DelayInterpOptions.none:
          delay_time2 = max(delay_time2, 0.0)
          return self.none(input, delay_time2)
        elif interp == DelayInterpOptions.linear:
          delay_time2 = max(delay_time2, 0.0)
          return self.linear_loc(input, delay_time2)
        elif interp == DelayInterpOptions.cubic:
          delay_time2 = max(delay_time2, self.two_sample_duration)
          return self.cubic_loc(input, delay_time2)
        elif interp == DelayInterpOptions.lagrange:
          delay_time2 = max(delay_time2, 0.0)
          return self.lagrange4(input, delay_time2)
        else: 
          delay_time2 = max(delay_time2, 0.0)
          return self.none(input, delay_time2)

    @doc_private
    fn get_read_idx_and_frac(mut self, delay_time: SIMD[DType.float64, self.N]) -> (SIMD[DType.int64, self.N], SIMD[DType.float64, self.N]):
        var float_sample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
        var float_read_idx: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N]((SIMD[DType.float64, self.N](self.write_idx) - float_sample_delay) % SIMD[DType.float64, self.N](self.max_delay_samples))
        var int_read_idx: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](float_read_idx)
        var frac = float_read_idx - SIMD[DType.float64, self.N](int_read_idx)
        return (int_read_idx, frac)

    @doc_private
    fn none(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
      var (read_idx, _) = self.get_read_idx_and_frac(delay_time)

      var out: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      @parameter
      for i in range(self.N):
          out[i] = self.delay_line[i][read_idx[i]]
      return out

    @doc_private
    fn linear_loc(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
      (read_idx, frac) = self.get_read_idx_and_frac(delay_time)
      var next_idx = (read_idx + 1) % self.max_delay_samples
      var samps: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      var next_samps: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

      @parameter
      for i in range(self.N):
        samps[i] = self.delay_line[i][read_idx[i]]
        next_samps[i] = self.delay_line[i][next_idx[i]]

      return lerp(samps, next_samps, frac)

    @doc_private
    fn cubic_loc(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:

      (read_idx, frac) = self.get_read_idx_and_frac(delay_time)

      # this is tested and ok: Mojo allows `negative_number` % `positive_number`
      # to yield a positive result, so we can safely use modulo for wrapping indices.
      var p0_idx = (read_idx - 1) % self.max_delay_samples
      var p1_idx = read_idx
      var p2_idx = (read_idx + 1) % self.max_delay_samples
      var p3_idx = (read_idx + 2) % self.max_delay_samples

      var p0: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      var p1: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      var p2: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      var p3: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

      @parameter
      for i in range(self.N):
        p0[i] = self.delay_line[i][p0_idx[i]]
        p1[i] = self.delay_line[i][p1_idx[i]]
        p2[i] = self.delay_line[i][p2_idx[i]]
        p3[i] = self.delay_line[i][p3_idx[i]]

      return cubic_interp(p0, p1, p2, p3, frac)

    @doc_private
    fn lagrange4(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Perform Lagrange interpolation for 4th order case (from JOS Faust Model)
        """

        var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate

        var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
        var frac = fsample_delay - SIMD[DType.float64, self.N](sample_delay)
        
        var p0: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var p1: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var p2: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var p3: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var p4: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

        @parameter
        for i in range(self.N):
            var read_idx = (self.write_idx - sample_delay[i]) % self.max_delay_samples
            p0[i] = self.delay_line[i][(read_idx) % self.max_delay_samples]
            p1[i] = self.delay_line[i][(read_idx - 1) % self.max_delay_samples]
            p2[i] = self.delay_line[i][(read_idx - 2) % self.max_delay_samples]
            p3[i] = self.delay_line[i][(read_idx - 3) % self.max_delay_samples]
            p4[i] = self.delay_line[i][(read_idx - 4) % self.max_delay_samples]

        return lagrange4(p0, p1, p2, p3, p4, frac)


struct Comb[N: Int = 1, interp: Int = 2](Representable, Movable, Copyable):
    """
    A simple comb filter using a delay line with feedback.
    
    """

    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp](self.world_ptr, max_delay)
        self.fb = SIMD[DType.float64, N](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N] = 0.0, feedback: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
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
        # writes to the buffer here instead
        # @parameter
        # for i in range(self.N):
        #     self.fb[i] = temp[i] # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "CombFilter"

struct LP_Comb[N: Int = 1, interp: Int = 0](Movable, Copyable):
    """
    A simple comb filter with an integrated one-pole low-pass filter.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1
      interp: The interpolation method to use (0 = linear, 2 = Lagrange).

    Args:
      world_ptr: Pointer to the MMMWorld instance.

      max_delay: The maximum delay time in seconds.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp] # Delay line without automatic feedback
    var one_pole: VAOnePole[N]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp](self.world_ptr, max_delay)
        self.one_pole = VAOnePole[N](world_ptr)
        self.fb = SIMD[DType.float64, N](0.0)

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N] = 0.0, feedback: SIMD[DType.float64, self.N] = 0.0, lp_freq: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
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

struct Allpass_Comb[N: Int = 1, interp: Int = 3](Representable, Movable, Copyable):
    """
    A simple all-pass comb filter using a delay line with feedback.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1

    Args:
      world_ptr: Pointer to the MMMWorld instance.
      max_delay: The maximum delay time in seconds.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp]
    var allpass_feedback: SIMD[DType.float64, N]
    var last_delay: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp](self.world_ptr, max_delay)
        self.allpass_feedback = 0.0
        self.last_delay = SIMD[DType.float64, self.N](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
        """Process one sample through the all-pass comb filter

        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
        Returns:
          The processed output sample.
        """
        temp = self.allpass_feedback + input
        temp2 = self.delay.next(temp, delay_time)  # Get the delayed sample and write to the delay line
        self.allpass_feedback = (temp2 * 0.5)
        
        out2 = temp * -0.5 + self.last_delay
        self.last_delay = temp2

        return out2

    fn __repr__(self) -> String:
        return "Allpass_Comb"

struct FB_Delay[N: Int = 1, interp: Int = 3](Representable, Movable, Copyable):
    """Like a Comb filter but with any amount of feedback and a tanh function."""

    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp]
    var dc: DCTrap[N]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp](self.world_ptr, max_delay)
        self.dc = DCTrap[N](world_ptr)
        self.fb = SIMD[DType.float64, N](0.0)

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N], feedback: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
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
