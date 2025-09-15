from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *

struct Delay[N: Int = 1](Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var max_delay_time: Float64
    var max_delay_samples: Int64
    var delay_line: List[List[Float64]]
    var write_ptr: Int64
    var delays: List[SIMD[DType.float64, N]]  # For Lagrange interpolation
    var offsets: SIMD[DType.float64, 4] 

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.max_delay_time = max_delay
        self.max_delay_samples = Int64(max_delay * self.world_ptr[0].sample_rate) + 1
        self.delay_line = [[Float64(0.0) for _ in range(self.max_delay_samples)] for _ in range(N)]
        self.write_ptr = 0
        self.delays = [SIMD[DType.float64, N](0.0) for _ in range(5)]
        self.offsets = SIMD[DType.float64, 4](1.0, 2.0, 3.0, 4.0)

    fn __repr__(self) -> String:
        return String("Delay(max_delay_time: " + String(self.max_delay_time) + ")")

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process one sample through the delay line.
        This function computes the average of two values.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).

        Returns:
          The processed output sample.

        """
        # return input
        return self.lagrange4(input, delay_time)

    fn lagrange4(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:

        """Perform Lagrange interpolation for 4 samples (from JOS Faust Model)."""

        # Write the current sample to the delay line
        self.write_ptr = (self.write_ptr + 1) % self.max_delay_samples

        var fsample_delay: SIMD[DType.float64, self.N] = delay_time * self.world_ptr[0].sample_rate
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

        for i in range(self.N):
            var fd_vec = SIMD[DType.float64, 4](fd[i], fd[i], fd[i], fd[i])
            
            var fd_minus_offsets = fd_vec - self.offsets  # [fd-1, fd-2, fd-3, fd-4] 

            
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

        for i in range(self.N):
            var coeffs: SIMD[DType.float64, 4] = SIMD[DType.float64, 4](coeff0[i], coeff1[i], coeff2[i], coeff3[i])

            var delays_simd = SIMD[DType.float64, 4](
                self.delay_line[i][read_ptr[i]],
                self.delay_line[i][(read_ptr[i] + 1) % self.max_delay_samples],
                self.delay_line[i][(read_ptr[i] + 2) % self.max_delay_samples], 
                self.delay_line[i][(read_ptr[i] + 3) % self.max_delay_samples],
            )

            var products = delays_simd * coeffs

            out[i] = products[0] + products[1] + products[2] + products[3] + (self.delay_line[i][(read_ptr[i] + 4) % self.max_delay_samples] * coeff4[i])

            self.delay_line[i][self.write_ptr] = input[i]

        return out

struct Comb[N: Int = 1](Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N](self.world_ptr, max_delay)

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: Float64 = 0.0, feedback: Float64 = 0.0, interp: Int64 = 0) -> SIMD[DType.float64, self.N]:
        """Process one sample through the comb filter.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).
          interp: The interpolation method to use (0 = linear, 1 = cubic, 2 = Lagrange).

        Returns:
          The processed output sample.

        """
        var out = self.delay.next(input, delay_time)  # Get the delayed sample
        temp = input + out * clip(feedback, 0.0, 1.0)  # Apply feedback
        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_ptr] = temp[i] # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "CombFilter"

struct FBDelay[N: Int = 1](Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay[N]
    var dc: DCTrap[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0):
        self.world_ptr = world_ptr
        self.delay = Delay[N](self.world_ptr, max_delay)
        self.dc = DCTrap[N](world_ptr)

    fn next(mut self, input: SIMD[DType.float64, self.N], delay_time: SIMD[DType.float64, self.N], feedback: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Like a Comb filter but with any amount of feedback and a tanh function.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).
          interp: The interpolation method to use (0 = linear, 1 = cubic, 2 = Lagrange).

        Returns:
          The processed output sample.

        """
        var out = self.delay.next(input, delay_time)  # Get the delayed sample

        temp = self.dc.next(tanh((input + out) * feedback))

        for i in range(self.N):
            self.delay.delay_line[i][self.delay.write_ptr] = temp[i] # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "FBDelay"



        # this is the crazy variable version of lagrange interp from the faust library...maybe later

        # fn select2(condition: Bool, true_val: Float64, false_val: Float64) -> Float64:
        #     """Select between two values based on a condition"""
        #     if condition:
        #         return true_val
        #     else:
        #         return false_val

        # fn fac(d: Float64, n: Int, k: Int) -> Float64:
        #     """Helper function: (d-k)/((n-k)+(n==k))"""
        #     var numerator = d - k
        #     var denominator = (n - k) + (1 if n == k else 0)
        #     return numerator / denominator

        # fn prod(self: Delay, start: Int, end: Int, func: fn(Int) -> Float64) -> Float64:
        #     """Compute product from start to end of func(i)"""
        #     if start > end:
        #         return 1.0
            
        #     var result: Float64 = 1.0
        #     for i in range(start, end + 1):
        #         result *= func(i)
        #     return result

        # fn facs1(N: Int, d: Float64, n: Int) -> Float64:
        #     """First factor: select2(n,1,prod(k,max(1,n),select2(k<n,1,fac(d,n,k))))"""
        #     if n == 1:
        #         return 1.0
            
        #     # Create a closure that captures d and n
        #     fn fac_wrapper(k: Int) -> Float64:
        #         if k < n:
        #             return fac(d, n, k)
        #         else:
        #             return 1.0
            
        #     var start_val = max(1, n)
        #     return self.prod(start_val, n, fac_wrapper)

        # fn facs2(N: Int, d: Float64, n: Int) -> Float64:
        #     """Second factor: select2(n<N,1,prod(l,max(1,N-n),fac(d,n,l+n+1)))"""
        #     if n >= N:
        #         return 1.0
            
        #     # Create a closure that captures d, n, and N
        #     fn fac_wrapper(l: Int) -> Float64:
        #         return fac(d, n, l + n + 1)
            
        #     var start_val = max(1, N - n)
        #     return prod(start_val, N - n, fac_wrapper)

        # fn h(N: Int, d: Float64, n: Int) -> Float64:
        #     """Main function: h(N,d,n) = facs1(N,d,n) * facs2(N,d,n)"""
        #     return facs1(N, d, n) * facs2(N, d, n)