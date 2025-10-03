from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *

struct Delay[N: Int = 1, interp: Int = 3, write_to_buffer: Bool = True](Representable, Movable, Copyable):
    """
    A variable delay line with Lagrange interpolation.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1

    Args:
      world_ptr: Pointer to the MMMWorld instance.
      max_delay: The maximum delay time in seconds.
    """

    var world_ptr: UnsafePointer[MMMWorld]
    var max_delay_time: Float64
    var max_delay_samples: Int64
    var delay_line: List[List[Float64]]
    var write_ptr: Int64
    var delays: List[SIMD[DType.float64, N]]  # For Lagrange interpolation

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay_time: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.max_delay_time = max_delay_time
        self.max_delay_samples = Int64(max_delay_time * self.world_ptr[0].sample_rate) + 1
        self.delay_line = [[Float64(0.0) for _ in range(self.max_delay_samples)] for _ in range(N)]
        self.write_ptr = 0
        self.delays = [SIMD[DType.float64, N](0.0) for _ in range(5)]

    fn __repr__(self) -> String:
        return String("Delay(max_delay_time: " + String(self.max_delay_time) + ")")

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process one sample through the delay line.
        This function computes the average of two values.

        next(input, delay_time)
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          interp: The interpolation method to use (0 = no interpolation, 2 = Lagrange).

        Returns:
          The processed output sample.

        """
        # return input
        @parameter
        if interp == 0:
            # no interpolation
            self.write_ptr = (self.write_ptr + 1) % self.max_delay_samples
            var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
            var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
            var read_ptr = (self.write_ptr - sample_delay) % self.max_delay_samples
            var out: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
            for i in range(self.N):
                out[i] = self.delay_line[i][read_ptr[i]]
                @parameter
                if write_to_buffer:
                  self.delay_line[i][self.write_ptr] = input[i]
          
            return out
        elif interp == 1:
          # linear interpolation
          self.write_ptr = (self.write_ptr + 1) % self.max_delay_samples
          var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
          var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
          var frac = fsample_delay - SIMD[DType.float64, self.N](sample_delay)
          var read_ptr = (self.write_ptr - sample_delay) % self.max_delay_samples
          var next_ptr = (read_ptr - 1) % self.max_delay_samples
          var samps: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
          var next_samps: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

          

          @parameter
          for i in range(self.N):
            samps[i] = self.delay_line[i][read_ptr[i]]
            next_samps[i] = self.delay_line[i][next_ptr[i]]

            @parameter
            if write_to_buffer:
              self.delay_line[i][self.write_ptr] = input[i]

          out = lerp(samps, next_samps, frac)
          return out
        elif interp == 2:
            # cubic interpolation
            return 0.0
        else:
            # Lagrange interpolation
          return self.lagrange4(input, delay_time)

    fn lagrange4(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Perform Lagrange interpolation for 4th order case (from JOS Faust Model)
        """

        # Write the current sample to the delay line
        self.write_ptr = (self.write_ptr + 1) % self.max_delay_samples

        var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
        @parameter
        for i in range(self.N):
            fsample_delay[i] = max(1.0, fsample_delay[i])

        var o = 1.49999
        var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
        var frac = fsample_delay - SIMD[DType.float64, self.N](sample_delay)
        var fd = o + frac

        # simd optimized!
        var out: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

        var read_ptr = (self.write_ptr - sample_delay) % self.max_delay_samples

        var fdm1: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var fdm2: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var fdm3: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        var fdm4: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

        offsets = SIMD[DType.float64, 4](1.0, 2.0, 3.0, 4.0)

        @parameter
        for i in range(self.N):
            var fd_vec = SIMD[DType.float64, 4](fd[i], fd[i], fd[i], fd[i])

            var fd_minus_offsets = fd_vec - offsets  # [fd-1, fd-2, fd-3, fd-4]

            fdm1[i] = fd_minus_offsets[0]
            fdm2[i] = fd_minus_offsets[1]
            fdm3[i] = fd_minus_offsets[2]
            fdm4[i] = fd_minus_offsets[3]

        # all this math is parallelized - for N > 4, this should be further optimized
        var coeff0 = fdm1 * fdm2 * fdm3 * fdm4 / 24.0
        var coeff1 = (0.0 - fd) * fdm2 * fdm3 * fdm4 / 6.0
        var coeff2 = fd * fdm1 * fdm3 * fdm4 / 4.0
        var coeff3 = (0.0 - fd * fdm1 * fdm2 * fdm4) / 6.0
        var coeff4 = fd * fdm1 * fdm2 * fdm3 / 24.0

        @parameter
        for i in range(self.N):
            coeffs: SIMD[DType.float64, 4] = SIMD[DType.float64, 4](coeff0[i], coeff1[i], coeff2[i], coeff3[i])

            delays_simd = SIMD[DType.float64, 4](
                self.delay_line[i][read_ptr[i]],
                self.delay_line[i][(read_ptr[i] - 1) % self.max_delay_samples],
                self.delay_line[i][(read_ptr[i] - 2) % self.max_delay_samples], 
                self.delay_line[i][(read_ptr[i] - 3) % self.max_delay_samples],
            )

            var products = delays_simd * coeffs

            out[i] = products.reduce_add() + (self.delay_line[i][(read_ptr[i] - 4) % self.max_delay_samples] * coeff4[i])

            @parameter
            if write_to_buffer:
              self.delay_line[i][self.write_ptr] = input[i]

        return out

struct Comb[N: Int = 1, interp: Int = 2](Representable, Movable, Copyable):
    """
    A simple comb filter using a delay line with feedback.
    
    """

    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp, False]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp, False](self.world_ptr, max_delay)

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
        var out = self.delay.next(input, delay_time)  
        temp = input + out * clip(feedback, 0.0, 1.0)  # Apply feedback

        # writes to the buffer here instead
        @parameter
        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_ptr] = temp[i] # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "CombFilter"

struct LP_Comb[N: Int = 1, interp: Int = 0](Representable, Movable, Copyable):
    """
    A simple comb filter with an integrated one-polelow-pass filter.
    
    Parameters:
      N: size of the SIMD vector - defaults to 1
      interp: The interpolation method to use (0 = linear, 2 = Lagrange).

    Args:
      world_ptr: Pointer to the MMMWorld instance.

      max_delay: The maximum delay time in seconds.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp, False] # Delay line without automatic feedback
    var one_pole: VAOnePole[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp, False](self.world_ptr, max_delay)
        self.one_pole = VAOnePole[N](self.world_ptr)

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
        var out = self.delay.next(input, delay_time)  # Get the delayed sample

        fb = self.one_pole.lpf(out * clip(feedback, 0.0, 1.0), lp_freq)  # Low-pass filter the feedback

        fb += input

        # writes to the buffer here instead of in the delay next() function
        @parameter
        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_ptr] = fb[i] # Apply feedback

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

struct FBDelay[N: Int = 1, interp: Int = 3](Representable, Movable, Copyable):
    """Like a Comb filter but with any amount of feedback and a tanh function."""

    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N, interp, False]
    var dc: DCTrap[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp, False](self.world_ptr, max_delay)
        self.dc = DCTrap[N](world_ptr)

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N], feedback: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process one sample or SIMD vector through the feedback delay.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).
          interp: The interpolation method to use (0 = linear, 1 = cubic, 2 = Lagrange).

        Returns:
          The processed output sample or SIMD vector.

        """
        var out = self.delay.next(input, delay_time)  # Get the delayed sample

        temp = self.dc.next(tanh((input + out) * feedback))

        # writes to the buffer here instead of in the delay next() function 
        @parameter
        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_ptr] = temp[i] 

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "FBDelay"
