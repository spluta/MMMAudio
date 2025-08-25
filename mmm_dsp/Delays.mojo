from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from math import tanh
from mmm_dsp.Filters import *

struct Delay(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var max_delay_time: Float64
    var max_delay_samples: Int64
    var delay_line: List[Float64]
    var write_ptr: Int64
    var delays: InlineArray[Float64, 5]  # For Lagrange interpolation

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0, interp: Int64 = 0):
        self.world_ptr = world_ptr
        self.max_delay_time = max_delay
        self.max_delay_samples = Int64(max_delay * self.world_ptr[0].sample_rate) + 1
        self.delay_line = List[Float64]()
        for _ in range(self.max_delay_samples):
            self.delay_line.append(0.0)  # Initialize delay line with zeros
        self.write_ptr = 0
        self.delays = InlineArray[Float64, 5](fill=0.0)

    fn __repr__(self) -> String:
        return String("Delay(max_delay_time: " + String(self.max_delay_time) + ")")

    fn next(mut self, input: Float64, delay_time: Float64 = 0.0, interp: Int64 = 0) -> Float64:
        """Process one sample through the delay line.
        This function computes the average of two values.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          interp: The interpolation method to use (0 = linear, 1 = cubic, 2 = Lagrange).

        Returns:
          The processed output sample.

        """

        if interp == 2:
            return self.lagrange4(input, delay_time)

        # Write the current sample to the delay line
        self.write_ptr = (self.write_ptr + 1) % self.max_delay_samples

        var fsample_delay: Float64 = max(1.0, delay_time * self.world_ptr[0].sample_rate)
        var sample_delay = Int64(fsample_delay)
        var frac = fsample_delay - Float64(sample_delay)

        var read_ptr = (self.write_ptr - sample_delay) % self.max_delay_samples
        var delayed_sample = self.delay_line[read_ptr]
        var read_ptr2 = (read_ptr + 1) % self.max_delay_samples
        var delayed_sample2 = self.delay_line[read_ptr2]

        # print((self.write_ptr - read_ptr) % self.max_delay_samples, frac)

        var out: Float64 = 0.0
        if (interp == 0):
            out = lin_interp(delayed_sample, delayed_sample2, frac)
        else:
            # read_ptr = (read_ptr + 1) % self.max_delay_samples
            # delayed_sample3 = self.delay_line[read_ptr]
            out = cubic_interpolation(delayed_sample, delayed_sample2, frac)

        self.delay_line[self.write_ptr] = input  

        return out

    fn lagrange4(mut self, input: Float64, delay_time: Float64 = 0.0) -> Float64:
        """Perform Lagrange interpolation for 4 samples (from JOS Faust Model)."""

        # Write the current sample to the delay line
        self.write_ptr = (self.write_ptr + 1) % self.max_delay_samples

        var fsample_delay: Float64 = max(1.5, delay_time * self.world_ptr[0].sample_rate) #jos 'd' value

        var o = 1.49999
        var sample_delay = Int64(fsample_delay)
        var frac = fsample_delay - Float64(sample_delay)
        var fd = o + frac
        var fdm1 = fd - 1.0
        var fdm2 = fd - 2.0
        var fdm3 = fd - 3.0
        var fdm4 = fd - 4.0

        var read_ptr = (self.write_ptr - sample_delay) % self.max_delay_samples
        self.delays[0] = self.delay_line[read_ptr]
        self.delays[1] = self.delay_line[(read_ptr + 1) % self.max_delay_samples]
        self.delays[2] = self.delay_line[(read_ptr + 2) % self.max_delay_samples]
        self.delays[3] = self.delay_line[(read_ptr + 3) % self.max_delay_samples]
        self.delays[4] = self.delay_line[(read_ptr + 4) % self.max_delay_samples]

        var out = (self.delays[0] * fdm1 * fdm2 * fdm3 * fdm4 / 24.0) + \
              (self.delays[1] * (0.0 - fd) * fdm2 * fdm3 * fdm4 / 6.0) + \
              (self.delays[2] * fd * fdm1 * fdm3 * fdm4 / 4.0) + \
              (self.delays[3] * (0.0 - fd * fdm1 * fdm2 * fdm4) / 6.0) + \
              (self.delays[4] * fd * fdm1 * fdm2 * fdm3 / 24.0)

        self.delay_line[self.write_ptr] = input  

        return out

struct Comb(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0, interp: Int64 = 0):
        self.world_ptr = world_ptr
        self.delay = Delay(self.world_ptr, max_delay, interp)

    fn next(mut self, input: Float64, delay_time: Float64 = 0.0, feedback: Float64 = 0.0, interp: Int64 = 0) -> Float64:
        """Process one sample through the comb filter.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).
          interp: The interpolation method to use (0 = linear, 1 = cubic, 2 = Lagrange).

        Returns:
          The processed output sample.

        """
        var out = self.delay.next(input, delay_time, interp)  # Get the delayed sample
        self.delay.delay_line[self.delay.write_ptr] = input + out * clip(feedback, 0.0, 1.0)  # Apply feedback

        return out  # Return the delayed sample

    fn __repr__(self) -> String:
        return "CombFilter"

struct FBDelay(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var delay: Delay
    # var svf: SVF
    var dc: DCTrap

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_delay: Float64 = 1.0, interp: Int64 = 0):
        self.world_ptr = world_ptr
        self.delay = Delay(self.world_ptr, max_delay, interp)
        # self.svf = SVF(world_ptr)
        self.dc = DCTrap(world_ptr)

    fn next(mut self, input: Float64, delay_time: Float64 = 0.0, feedback: Float64 = 0.0, interp: Int64 = 0) -> Float64:
        """Like a Comb filter but with any amount of feedback and a tanh function.
        
        Args:
          input: The input sample to process.
          delay_time: The amount of delay to apply (in seconds).
          feedback: The amount of feedback to apply (0.0 to 1.0).
          interp: The interpolation method to use (0 = linear, 1 = cubic, 2 = Lagrange).

        Returns:
          The processed output sample.

        """
        var out = self.delay.next(input, delay_time, interp)  # Get the delayed sample
        self.delay.delay_line[self.delay.write_ptr] = self.dc.next(tanh((input + out) * feedback))  # Apply feedback

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