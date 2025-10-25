from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *
from sys import simd_width_of
from algorithm import vectorize
from mmm_dsp.Filters import VAOnePole, DCTrap

struct InterpOptions:
    alias no_interp: Int = 0
    alias linear_interp: Int = 1
    alias cubic_interp: Int = 2
    alias lagrange4: Int = 3

alias simd_width = simd_width_of[DType.float64]()*2

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
    var write_idx: Int64
    var fd_dels: InlineArray[SIMD[DType.float64, N], 5]  # For Lagrange interpolation
    var coeffs: InlineArray[SIMD[DType.float64, N], 5]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay_time: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.max_delay_time = max_delay_time
        self.max_delay_samples = Int64(max_delay_time * self.world_ptr[0].sample_rate) + 1
        self.delay_line = [[Float64(0.0) for _ in range(self.max_delay_samples)] for _ in range(N)]
        self.write_idx = 0
        self.fd_dels = InlineArray[SIMD[DType.float64, N], 5](fill=SIMD[DType.float64, N](0.0))
        self.coeffs = InlineArray[SIMD[DType.float64, N], 5](fill=SIMD[DType.float64, N](0.0))

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
        # return input
        self.write_idx = (self.write_idx + 1) % self.max_delay_samples

        @parameter
        if interp == InterpOptions.no_interp:
          return self.no_interp(input, delay_time)
        elif interp == InterpOptions.linear_interp:
            return self.linear_interp_loc(input, delay_time)
        elif interp == InterpOptions.cubic_interp:
            return self.cubic_interp_loc(input, delay_time)
        elif interp == InterpOptions.lagrange4:
          return self.lagrange4(input, delay_time)

    @doc_private
    fn get_read_idx(mut self, delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.int64, self.N]:
        var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
        var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
        var read_idx = (self.write_idx - sample_delay) % self.max_delay_samples
        return read_idx

    @doc_private
    fn get_read_idx_and_frac(mut self, delay_time: SIMD[DType.float64, self.N]) -> (SIMD[DType.int64, self.N], SIMD[DType.float64, self.N]):
        var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
        var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
        var read_idx = (self.write_idx - sample_delay) % self.max_delay_samples
        var frac = fsample_delay - SIMD[DType.float64, self.N](sample_delay)
        return (read_idx, frac)

    @doc_private
    fn no_interp(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
      var read_idx = self.get_read_idx(delay_time)

      var out: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      @parameter
      for i in range(self.N):
          out[i] = self.delay_line[i][read_idx[i]]
          @parameter
          if write_to_buffer:
            self.delay_line[i][self.write_idx] = input[i]
      return out

    @doc_private
    fn linear_interp_loc(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
      var (read_idx, frac) = self.get_read_idx_and_frac(delay_time)
      var next_idx = (read_idx - 1) % self.max_delay_samples
      var samps: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
      var next_samps: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

      @parameter
      for i in range(self.N):
        samps[i] = self.delay_line[i][read_idx[i]]
        next_samps[i] = self.delay_line[i][next_idx[i]]

      @parameter
      if write_to_buffer:
          @parameter
          for i in range(self.N):
              self.delay_line[i][self.write_idx] = input[i]

      return lerp(samps, next_samps, frac)

    @doc_private
    fn cubic_interp_loc(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
      var (read_idx, frac) = self.get_read_idx_and_frac(delay_time)
      # this is tested and ok: Mojo allows `negative_number` % `positive_number`
      # to yield a positive result, so we can safely use modulo for wrapping indices.
      var p0_idx = (read_idx - 2) % self.max_delay_samples
      var p1_idx = (read_idx - 1) % self.max_delay_samples
      var p2_idx = (read_idx) % self.max_delay_samples
      var p3_idx = (read_idx + 1) % self.max_delay_samples

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

      @parameter
      if write_to_buffer:
          @parameter
          for i in range(self.N):
              self.delay_line[i][self.write_idx] = input[i]

      return cubic_interp(p0, p1, p2, p3, frac)

    @doc_private
    fn lagrange4(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Perform Lagrange interpolation for 4th order case (from JOS Faust Model)
        """

        var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
        @parameter
        for i in range(self.N):
            fsample_delay[i] = max(1.0, fsample_delay[i])

        var o = 1.49999
        var sample_delay = SIMD[DType.int64, self.N](fsample_delay)
        var frac = fsample_delay - SIMD[DType.float64, self.N](sample_delay)
        var fd = o + frac

        var out: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)

        var read_idx = (self.write_idx - sample_delay) % self.max_delay_samples

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
                self.delay_line[i][read_idx[i]],
                self.delay_line[i][(read_idx[i] - 1) % self.max_delay_samples],
                self.delay_line[i][(read_idx[i] - 2) % self.max_delay_samples],
                self.delay_line[i][(read_idx[i] - 3) % self.max_delay_samples],
            )

            var products = delays_simd * coeffs

            out[i] = products.reduce_add() + (self.delay_line[i][(read_idx[i] - 4) % self.max_delay_samples] * coeff4[i])

            @parameter
            if write_to_buffer:
              self.delay_line[i][self.write_idx] = input[i]

        return out

struct DelayN[N: Int = 2, interp: Int = 3, write_to_buffer: Bool = True](Movable, Copyable):
    var list: List[Delay[simd_width, interp, write_to_buffer]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        alias num_simd = N // simd_width + (0 if N % simd_width == 0 else 1)
        self.list = [Delay[simd_width, interp, write_to_buffer](world_ptr) for _ in range(num_simd)]

    @always_inline
    fn next(mut self, ref in_list: List[Float64], mut out_list: List[Float64], ref arg0: List[Float64]):
        vals = SIMD[DType.float64, simd_width](0.0)
        arg0_simd = SIMD[DType.float64, simd_width](0.0)
        N = len(out_list)

        @parameter
        fn closure[width: Int](i: Int):
            @parameter
            for j in range(simd_width):
                vals[j] = in_list[(j + i) % len(in_list)]
                arg0_simd[j] = arg0[(j + i) % len(arg0)]  # wrap around if not enough args

            temp = self.list[i // simd_width].next(vals, arg0_simd)
            @parameter
            for j in range(simd_width):
                idx = i + j
                if idx < N:
                    out_list[idx] = temp[j]
        vectorize[closure, simd_width](N)

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
            self.delay.delay_line[i][self.delay.write_idx] = temp[i] # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "CombFilter"

# struct CombN[N: Int = 2](Movable, Copyable):
#     var list: List[Comb[simd_width]]

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         alias num_simd = N // simd_width + (0 if N % simd_width == 0 else 1)
#         self.list = [Comb[simd_width](world_ptr) for _ in range(num_simd)]

#     fn next(mut self, ref in_list: List[Float64], mut out_list: List[Float64], arg0: List[Float64], arg1: List[Float64]):
#         vals = SIMD[DType.float64, simd_width](0.0)
#         arg0_simd = SIMD[DType.float64, simd_width](0.0)
#         arg1_simd = SIMD[DType.float64, simd_width](0.0)
#         N = len(out_list)

#         @parameter
#         fn closure[width: Int](i: Int):
#             @parameter
#             for j in range(simd_width):
#                 vals[j] = in_list[j + i]
#                 arg0_simd[j] = arg0[(j + i)%len(arg0)]  # wrap around if not enough args
#                 arg1_simd[j] = arg1[(j + i)%len(arg1)]  # wrap around if not enough args

#             temp = self.list[i // simd_width].next(vals, arg0_simd, arg1_simd)
#             @parameter
#             for j in range(simd_width):
#                 idx = i + j
#                 if idx < N:
#                     out_list[idx] = temp[j]
#         vectorize[closure, simd_width](N)

struct LP_Comb[N: Int = 1, interp: Int = 0](Representable, Movable, Copyable):
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
    var delay: Delay[N, interp, False] # Delay line without automatic feedback
    var one_pole: VAOnePole[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N, interp, False](self.world_ptr, max_delay)
        self.one_pole = VAOnePole[N](world_ptr)

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
        var out = self.delay.next(input, delay_time)  # Get the delayed sample

        fb = self.one_pole.lpf(out * clip(feedback, 0.0, 1.0), lp_freq)  # Low-pass filter the feedback
        # coef = exp(-2.0 * pi * lp_freq / self.world_ptr[0].sample_rate)
        # fb = self.one_pole.next(out, coef)

        fb += input

        # writes to the buffer here instead of in the delay next() function
        @parameter
        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_idx] = fb[i] # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "LP_Comb"

struct LP_CombN[N: Int = 2](Movable, Copyable):
    var list: List[LP_Comb[simd_width]]
    var arg0_simd: SIMD[DType.float64, simd_width]
    var arg1_simd: SIMD[DType.float64, simd_width]
    var arg2_simd: SIMD[DType.float64, simd_width]
    var vals: SIMD[DType.float64, simd_width]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        alias num_simd = N // simd_width + (0 if N % simd_width == 0 else 1)
        self.list = [LP_Comb[simd_width](world_ptr) for _ in range(num_simd)]
        self.arg0_simd = SIMD[DType.float64, simd_width](0.0)
        self.arg1_simd = SIMD[DType.float64, simd_width](0.0)
        self.arg2_simd = SIMD[DType.float64, simd_width](0.0)
        self.vals = SIMD[DType.float64, simd_width](0.0)

    @always_inline
    fn next(mut self, ref in_list: List[Float64], mut out_list: List[Float64], ref delay_time: List[Float64], ref feedback: List[Float64], ref lpf: List[Float64]):
        N = len(out_list)
        in_len = len(in_list)
        delay_len = len(delay_time)
        feedback_len = len(feedback)
        lpf_len = len(lpf)

        @parameter
        fn closure[width: Int](i: Int):
            # Check if we can do direct SIMD loads (no wrapping needed)
            can_direct_load = (i + simd_width <= in_len and 
                                  i + simd_width <= delay_len and 
                                  i + simd_width <= feedback_len and 
                                  i + simd_width <= lpf_len)
            
            if can_direct_load:
                # Fast path: direct SIMD loads
                self.vals = in_list.unsafe_ptr().load[width=simd_width](i)
                self.arg0_simd = delay_time.unsafe_ptr().load[width=simd_width](i)
                self.arg1_simd = feedback.unsafe_ptr().load[width=simd_width](i)
                self.arg2_simd = lpf.unsafe_ptr().load[width=simd_width](i)
            else:
                # Slow path: element-wise with wrapping
                @parameter
                for j in range(simd_width):
                    self.vals[j] = in_list[(j + i) % in_len]
                    self.arg0_simd[j] = delay_time[(j + i) % delay_len]
                    self.arg1_simd[j] = feedback[(j + i) % feedback_len]
                    self.arg2_simd[j] = lpf[(j + i) % lpf_len]

            temp = self.list[i // simd_width].next(self.vals, self.arg0_simd, self.arg1_simd, self.arg2_simd)
            
            # Optimized output store
            remaining = N - i
            if remaining >= simd_width:
                out_list.unsafe_ptr().store(i, temp)
            else:
                @parameter
                for j in range(simd_width):
                    if j < remaining:
                        out_list[i + j] = temp[j]
        
        vectorize[closure, simd_width](N)

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

        Returns:
          The processed output sample or SIMD vector.

        """
        var out = self.delay.next(input, delay_time)  # Get the delayed sample

        temp = self.dc.next(tanh((input + out) * feedback))

        # writes to the buffer here instead of in the delay next() function 
        @parameter
        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_idx] = temp[i]

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "FBDelay"
