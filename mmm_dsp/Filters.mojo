from mmm_src.MMMWorld import MMMWorld
from math import exp, sqrt, tan, pi, tanh, ceil, floor
from bit import next_power_of_two
from mmm_utils.functions import *

from sys import simd_width_of
from algorithm import vectorize
from .Oversampling import Oversampling


# Lag is super vectorized for processing in parallel
struct Lag[N: Int=1](Representable, Movable, Copyable):
    """A lag processor that smooths input values over time based on a specified lag time in seconds.
    """
    alias SIMD_vec = SIMD[DType.float64, N]
    var val: Self.SIMD_vec
    var b1: Self.SIMD_vec
    var lag: Self.SIMD_vec
    var log001: Float64
    var world_ptr: UnsafePointer[MMMWorld]

    alias width = 2 * simd_width_of[DType.float64]()
    var num_simds: Int
    var in_simd: SIMD[DType.float64, Self.width]
    var lag_simd: SIMD[DType.float64, Self.width]
    var val_simd: SIMD[DType.float64, Self.width]
    var b1_simd: SIMD[DType.float64, Self.width]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.val = self.SIMD_vec(0.0)
        self.b1 = self.SIMD_vec(0.0)
        self.lag = self.SIMD_vec(0.0)
        self.world_ptr = world_ptr
        self.log001 = -6.907755278982137  # log(0.01) for lag calculations, precomputed for efficiency

        self.num_simds = Int(ceil(self.N / self.width))
        self.in_simd = SIMD[DType.float64, self.width](0.0)
        self.lag_simd = SIMD[DType.float64, self.width](0.0)
        self.val_simd = SIMD[DType.float64, self.width](0.0)
        self.b1_simd = SIMD[DType.float64, self.width](0.0)

    fn __repr__(self) -> String:
        return String("Lag")

    fn get_small_simd(mut self, in_samp: self.SIMD_vec, j: Int):
        for i in range(self.width):
            var idx = j * self.width + i
            if idx < self.N:
                self.in_simd[i] = in_samp[idx]
                self.lag_simd[i] = self.lag[idx]
                self.val_simd[i] = self.val[idx]
                self.b1_simd[i] = self.b1[idx]
            else:
                self.in_simd[i] = 0.0
                self.lag_simd[i] = 0.0
                self.val_simd[i] = 0.0
                self.b1_simd[i] = 0.0

    fn put_small_simd(mut self, j: Int):
        for i in range(self.width):
            var idx = j * self.width + i
            if idx < self.N:
                self.val[idx] = self.val_simd[i]
                self.lag[idx] = self.lag_simd[i]
                self.b1[idx] = self.b1_simd[i]

    fn next(mut self: Lag, var in_samp: self.SIMD_vec, lag: self.SIMD_vec = self.SIMD_vec(0.05), num_lags: Int = self.N) -> self.SIMD_vec:
        # the number of simd loops

        lower = min(num_lags, self.N)
        num_SIMDs = Int(floor(Float64(lower) / Float64(self.width)))
        carry = lower - num_SIMDs * self.width

        # print("num_SIMDs: " + String(num_SIMDs) + " carry: " + String(carry) + " lower: " + String(lower) + " self.N: " + String(self.N))

        # for j in range(num_SIMDs):
        #     self.get_small_simd(in_samp, j)

        #     var change = False
        #     for i in range(self.width): 
        #         var idx = j * self.width + i
        #         if self.lag_simd[i] != lag[idx]:
        #             self.lag_simd[i] = lag[idx]
        #             change = True
        #     if not change:
        #         self.val_simd = self.in_simd + self.b1_simd * (self.val_simd - self.in_simd)
        #     else:
        #         for i in range(self.width):
        #             if self.lag_simd[i] == 0.0:
        #                 self.b1_simd[i] = 0.0
        #             else:
        #                 # Calculate the lag coeficient based on the sample rate
        #                 self.b1_simd[i] = exp(self.log001 / (self.lag_simd[i] * self.world_ptr[0].sample_rate))

        #         # self.lag = self.lag_simd
        #         self.val_simd = self.in_simd + self.b1_simd * (self.val_simd - self.in_simd)

        #     self.val_simd = sanitize(self.val_simd)

        #     self.put_small_simd(j)
        #     for i in range(self.width):
        #         var idx = j * self.width + i
        #         if idx < self.N:
        #             in_samp[idx] = self.val_simd[i]
        
        @parameter
        fn process_block[simd_width: Int](j: Int):
            self.get_small_simd(in_samp, j)
            var change = False
            for i in range(simd_width):
                var idx = j * simd_width + i
                if self.lag_simd[i] != lag[idx]:
                    self.lag_simd[i] = lag[idx]
                    change = True
            if not change:
                self.val_simd = self.in_simd + self.b1_simd * (self.val_simd - self.in_simd)
            else:
                for i in range(simd_width):
                    if self.lag_simd[i] == 0.0:
                        self.b1_simd[i] = 0.0
                    else:
                        self.b1_simd[i] = exp(self.log001 / (self.lag_simd[i] * self.world_ptr[0].sample_rate))
                self.val_simd = self.in_simd + self.b1_simd * (self.val_simd - self.in_simd)
            self.val_simd = sanitize(self.val_simd)
            self.put_small_simd(j)
            for i in range(simd_width):
                var idx = j * simd_width + i
                if idx < self.N:
                    in_samp[idx] = self.val_simd[i]
        
        vectorize[process_block, self.width](num_SIMDs)

        # go through the carries one by one
        start_at = num_SIMDs * self.width
        for i in range(carry):
            var change = False
            var idx = start_at + i
            if self.lag[idx] != lag[idx]:
                self.lag[idx] = lag[idx]
                change = True
            if not change:
                self.val[idx] = in_samp[idx] + self.b1[idx] * (self.val[idx] - in_samp[idx])
            else:
                if self.lag[idx] == 0.0:
                    self.b1[idx] = 0.0
                else:
                    # Calculate the lag coeficient based on the sample rate
                    self.b1[idx] = exp(self.log001 / (self.lag[idx] * self.world_ptr[0].sample_rate))

                self.val[idx] = in_samp[idx] + self.b1[idx] * (self.val[idx] - in_samp[idx])
            self.val[idx] = sanitize(self.val[idx])
            in_samp[idx] = self.val[idx]

        return in_samp

struct SVF[N: Int = 1](Representable, Movable, Copyable):
    """State Variable Filter implementation translated from Oleg Nesterov's Faust implementation"""

    var ic1eq: SIMD[DType.float64, N]  # Internal state 1
    var ic2eq: SIMD[DType.float64, N]  # Internal state 2
    var sample_rate: Float64
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the SVF with given sample rate"""
        self.ic1eq = SIMD[DType.float64, N](0.0)
        self.ic2eq = SIMD[DType.float64, N](0.0)
        self.sample_rate = world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String("SVF")

    fn reset(mut self):
        """Reset internal state"""
        self.ic1eq = SIMD[DType.float64, N](0.0)
        self.ic2eq = SIMD[DType.float64, N](0.0)

    fn _compute_coeficients(self, filter_type: SIMD[DType.int32, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> (SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N]):
        """Compute filter coeficients based on type and parameters"""
        
        # Compute A (gain factor)
        var A: SIMD[DType.float64, self.N] = pow(SIMD[DType.float64, self.N](10.0), gain_db / 40.0)

        # Compute g (frequency warping)
        var base_g = tan(frequency * pi / self.sample_rate)
        var g: SIMD[DType.float64, self.N]
        if filter_type == 7:  # lowshelf
            g = base_g / sqrt(A)
        elif filter_type == 8:  # highshelf
            g = base_g * sqrt(A)
        else:
            g = base_g
        
        # Compute k (resonance factor)
        var k: SIMD[DType.float64, self.N]
        if filter_type == 6:  # bell
            k = 1.0 / (q * A)
        else:
            k = 1.0 / q
        
        # Get mix coeficients based on filter type
        var mix_coefs = self._get_mix_coeficients(filter_type, k, A)
        
        return (g, k, mix_coefs[0], mix_coefs[1], mix_coefs[2])

    fn _get_mix_coeficients(self, filter_type: SIMD[DType.int32, self.N], k: SIMD[DType.float64, self.N], A: SIMD[DType.float64, self.N]) -> (SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N]):
        """Get mixing coeficients for different filter types"""
        
        mc0 = SIMD[DType.float64, self.N](1.0)
        mc1 = SIMD[DType.float64, self.N](0.0)
        mc2 = SIMD[DType.float64, self.N](0.0)

        for i in range(self.N):
            if filter_type[i] == 0:      # lowpass
                mc0[i], mc1[i], mc2[i] = 0.0, 0.0, 1.0
            elif filter_type[i] == 1:    # bandpass
                mc0[i], mc1[i], mc2[i] = 0.0, 1.0, 0.0
            elif filter_type[i] == 2:    # highpass
                mc0[i], mc1[i], mc2[i] = 1.0, -k[i], -1.0
            elif filter_type[i] == 3:    # notch
                mc0[i], mc1[i], mc2[i] = 1.0, -k[i], 0.0
            elif filter_type[i] == 4:    # peak
                mc0[i], mc1[i], mc2[i] = 1.0, -k[i], -2.0
            elif filter_type[i] == 5:    # allpass
                mc0[i], mc1[i], mc2[i] = 1.0, -2.0*k[i], 0.0
            elif filter_type[i] == 6:    # bell
                mc0[i], mc1[i], mc2[i] = 1.0, k[i]*(A[i]*A[i] - 1.0), 0.0
            elif filter_type[i] == 7:    # lowshelf
                mc0[i], mc1[i], mc2[i] = 1.0, k[i]*(A[i] - 1.0), A[i]*A[i] - 1.0
            elif filter_type[i] == 8:    # highshelf
                mc0[i], mc1[i], mc2[i] = A[i]*A[i], k[i]*(1.0 - A[i])*A[i], 1.0 - A[i]*A[i]
            else:
                mc0[i], mc1[i], mc2[i] = 1.0, 0.0, 0.0  # default

        return (mc0, mc1, mc2)

        # if filter_type == 0:      # lowpass
        #     return (SIMD[DType.float64, self.N](0.0), SIMD[DType.float64, self.N](0.0), SIMD[DType.float64, self.N](1.0))
        # elif filter_type == 1:    # bandpass
        #     return (SIMD[DType.float64, self.N](0.0), SIMD[DType.float64, self.N](1.0), SIMD[DType.float64, self.N](0.0))
        # elif filter_type == 2:    # highpass
        #     return (SIMD[DType.float64, self.N](1.0), -k, -SIMD[DType.float64, self.N](1.0))
        # elif filter_type == 3:    # notch
        #     return (SIMD[DType.float64, self.N](1.0), -k, SIMD[DType.float64, self.N](0.0))
        # elif filter_type == 4:    # peak
        #     return (SIMD[DType.float64, self.N](1.0), -k, -SIMD[DType.float64, self.N](2.0))
        # elif filter_type == 5:    # allpass
        #     return (SIMD[DType.float64, self.N](1.0), -2.0*k, SIMD[DType.float64, self.N](0.0))
        # elif filter_type == 6:    # bell
        #     return (SIMD[DType.float64, self.N](1.0), k*(A*A - 1.0), SIMD[DType.float64, self.N](0.0))
        # elif filter_type == 7:    # lowshelf
        #     return (SIMD[DType.float64, self.N](1.0), k*(A - 1.0), A*A - 1.0)
        # elif filter_type == 8:    # highshelf
        #     return (A*A, k*(1.0 - A)*A, 1.0 - A*A)
        # else:
        #     return (SIMD[DType.float64, self.N](1.0), SIMD[DType.float64, self.N](0.0), SIMD[DType.float64, self.N](0.0))  # default

    fn next(mut self, input: SIMD[DType.float64, self.N], filter_type: SIMD[DType.int32, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
        """next a single sample through the SVF"""
        
        var coefs = self._compute_coeficients(filter_type, frequency, q, gain_db)
        var g = coefs[0]
        var k = coefs[1]
        var mix_a = coefs[2]
        var mix_b = coefs[3]
        var mix_c = coefs[4]

        # Compute the tick function
        var denominator = 1.0 + g * (g + k)
        var v1 = (self.ic1eq + g * (input - self.ic2eq)) / denominator
        var v2 = self.ic2eq + g * v1
        
        # Update internal state (2*v1 - ic1eq, 2*v2 - ic2eq)
        self.ic1eq = 2.0 * v1 - self.ic1eq
        self.ic2eq = 2.0 * v2 - self.ic2eq
        
        # Mix the outputs: mix_a*v0 + mix_b*v1 + mix_c*v2
        return mix_a * input + mix_b * v1 + mix_c * v2
    
    # Convenience methods for different filter types
    fn lpf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Lowpass filter"""
        return self.next(input, 0, frequency, q)

    fn bpf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Bandpass filter"""
        return self.next(input, 1, frequency, q)

    fn hpf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Highpass filter"""
        return self.next(input, 2, frequency, q)

    fn notch(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Notch filter"""
        return self.next(input, 3, frequency, q)

    fn peak(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Peak filter"""
        return self.next(input, 4, frequency, q)

    fn allpass(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Allpass filter"""
        return self.next(input, 5, frequency, q)

    fn bell(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Bell filter (parametric EQ)"""
        return self.next(input, 6, frequency, q, gain_db)

    fn lowshelf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Low shelf filter"""
        return self.next(input, 7, frequency, q, gain_db)

    fn highshelf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """High shelf filter"""
        return self.next(input, 8, frequency, q, gain_db)

struct lpf_LR4[N: Int = 1](Representable, Movable, Copyable):
    var svf1: SVF[N]
    var svf2: SVF[N]
    var q: Float64


    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.svf1 = SVF[self.N](world_ptr)
        self.svf2 = SVF[self.N](world_ptr)
        self.q = 1.0 / sqrt(2.0)  # 1/sqrt(2) for Butterworth response

    fn __repr__(self) -> String:
        return String("lpf_LR4")

    fn set_sample_rate(mut self, sample_rate: Float64):
        self.svf1.sample_rate = sample_rate
        self.svf2.sample_rate = sample_rate

    fn next(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """a single sample through the 4th order lowpass filter."""
        # First stage
        var cf = self.svf1.lpf(input, frequency, self.q)  # First stage
        # Second stage
        return self.svf2.lpf(cf, frequency, self.q)  # Second stage

struct OnePole(Representable, Movable, Copyable):
    """
    Simple one-pole IIR filter that can be configured as lowpass or highpass
    """
    var last_samp: Float64  # Previous output
    var sample_rate: Float64
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the one-pole filter"""

        self.last_samp = 0.0
        self.sample_rate = world_ptr[0].sample_rate
    
    fn __repr__(self) -> String:
        return String("OnePoleFilter")
    
    fn next(mut self, input: Float64, coef: Float64) -> Float64:
        """Process one sample through the filter"""
        var output = (1 - abs(coef)) * input + coef * self.last_samp
        self.last_samp = output
        return output

struct Integrator(Representable, Movable, Copyable):
    """
    Simple one-pole IIR filter that can be configured as lowpass or highpass
    """
    var last_samp: Float64  # Previous output
    var sample_rate: Float64
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.last_samp = 0.0
        self.sample_rate = world_ptr[0].sample_rate
    
    fn __repr__(self) -> String:
        return String("Integrator")
    
    fn next(mut self, input: Float64, coef: Float64) -> Float64:
        """Process one sample through the filter"""
        var output = input + coef * self.last_samp
        self.last_samp = output
        return output

# needs to be tested and updated to SIMD
# struct OneZero(Representable, Movable, Copyable):
#     """
#     Simple one-zero filter
#     """
#     var last_samp: Float64  # Previous output
#     var sample_rate: Float64
    
#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         """Initialize the one-zero filter"""

#         self.last_samp = 0.0
#         self.sample_rate = world_ptr[0].sample_rate
    
#     fn __repr__(self) -> String:
#         return String("OnePoleFilter")
    
#     fn next(mut self, input: Float64, coef: Float64) -> Float64:
#         """Process one sample through the filter"""
#         var output = input - coef * self.last_samp
#         self.last_samp = output
#         return output

struct DCTrap[N: Int=1](Representable, Movable, Copyable):
    """DC Trap from Digital Sound Generation by Beat Frei.

    Arguments:
        input: The input signal to process.
    """

    var alpha: Float64
    var last_samp: SIMD[DType.float64, N]
    var last_inner: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the DC blocker filter"""
        self.alpha = 2 * pi * 5.0 / world_ptr[0].sample_rate  # 5 Hz cutoff frequency
        self.last_samp = SIMD[DType.float64, N](0.0)
        self.last_inner = SIMD[DType.float64, N](0.0)

    fn __repr__(self) -> String:
        return String("DCBlockerFilter")

    fn next(mut self, in_: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        """Process one sample through the DC blocker filter"""
        var out = self.last_samp * self.alpha + self.last_inner
        
        self.last_inner = out

        out = in_ - out
        self.last_samp = out

        return out

struct VAOnePole[N: Int = 1](Representable, Movable, Copyable):
    """
    One-pole filter based on the Virtual Analog design by Vadim Zavalishin in "The Art of VA Filter Design"
    (http://www.cytomic.com/files/Audio-EQ-Cookbook.txt)
    This implementation supports both lowpass and highpass modes.

    Parameters:
        N: Number of channels to process in parallel.
    Methods:
        lpf(input, freq): Process input through a lowpass filter with cutoff frequency freq.
        hpf(input, freq): Process input through a highpass filter with cutoff frequency freq.
    """

    var last_1: SIMD[DType.float64, N]  # Previous output
    var step_val: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.last_1 = SIMD[DType.float64, N](0.0)
        self.step_val = 1.0 / world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String(
            "VAOnePole"
        )

    fn lpf(mut self, input: SIMD[DType.float64, N], freq: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        """
        Process one sample through the VA one-pole lowpass filter.
        
        Parameters:
            input: The input signal to process.
            freq: The cutoff frequency of the lowpass filter.
        
        """

        # var omegaWarp = tan(pi * cf * self.step_val)
        # var g = omegaWarp / (1.0 + omegaWarp)
        var g =  tan(pi * freq * self.step_val)

        var G = g / (1.0 + g)

        var v = (input - self.last_1) * G

        var output = self.last_1 + v
        self.last_1 = v + output
        return output

    fn hpf(mut self, input: SIMD[DType.float64, N], freq: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        return input - self.lpf(input, freq)

struct VAMoogLadder[N: Int = 1](Representable, Movable, Copyable):
    var nyquist: Float64
    var step_val: Float64
    var last_1: SIMD[DType.float64, N]
    var last_2: SIMD[DType.float64, N]
    var last_3: SIMD[DType.float64, N]
    var last_4: SIMD[DType.float64, N]
    var oversampling: Oversampling[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.nyquist = world_ptr[0].sample_rate * 0.5
        self.step_val = 1.0 / world_ptr[0].sample_rate
        self.last_1 = SIMD[DType.float64, N](0.0)
        self.last_2 = SIMD[DType.float64, N](0.0)
        self.last_3 = SIMD[DType.float64, N](0.0)
        self.last_4 = SIMD[DType.float64, N](0.0)
        self.oversampling = Oversampling[self.N](world_ptr)

    fn __repr__(self) -> String:
        return String(
            "VAMoogLadder"
        )

    fn next(mut self, sig: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q_val: SIMD[DType.float64, self.N], os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        
        if self.oversampling.index != os_index:
            self.oversampling.set_os_index(os_index)

        for _ in range(self.oversampling.times_os_int):
            var cf = clip(freq, 0.0, self.nyquist * 0.6)
            
            # k is the feedback coefficient of the entire circuit
            var k = 4.0 * q_val
            
            var omegaWarp = tan(pi * cf * self.step_val)
            var g = omegaWarp / (1.0 + omegaWarp)
            
            var g4 = g * g * g * g
            var s4 = g * g * g * (self.last_1 * (1 - g)) + g * g * (self.last_2 * (1 - g)) + g * (self.last_3 * (1 - g)) + (self.last_4 * (1 - g))
            
            # internally clips the feedback signal to prevent the filter from blowing up
            for i in range(self.N):
                if s4[i] > 2.0:
                    s4[i] = tanh(s4[i] - 1.0) + 1.0
                elif s4[i] < -2.0:
                    s4[i] = tanh(s4[i] + 1.0) - 1.0

            # input is the incoming signal minus the feedback from the last stage
            var input = (sig - k * s4) / (1.0 + k * g4)

            var v1 = g * (input - self.last_1)
            var lp1 = self.last_1 + v1
            
            var v2 = g * (lp1 - self.last_2)
            var lp2 = self.last_2 + v2
            
            var v3 = g * (lp2 - self.last_3)
            var lp3 = self.last_3 + v3
            
            var v4 = g * (lp3 - self.last_4)
            var lp4 = self.last_4 + v4
            
            self.last_1 = lp1
            self.last_2 = lp2
            self.last_3 = lp3
            self.last_4 = lp4
            
            if self.oversampling.index == 0:
                return lp4
            else:
                self.oversampling.add_sample(lp4)
        return self.oversampling.get_sample()

# All of the following is a translation of Julius Smith's Faust implementation of digital filters.
# Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>

struct FIR[N: Int = 1](Representable, Movable, Copyable):
    var buffer: List[SIMD[DType.float64, N]]
    var index: Int

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_coeffs: Int):
        self.buffer = [SIMD[DType.float64, N](0.0) for _ in range(num_coeffs)]
        self.index = 0

    fn __repr__(self) -> String:
        return String("FIR")

    fn next(mut self: FIR, input: SIMD[DType.float64, self.N], coeffs: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
        self.buffer[self.index] = input
        var output = SIMD[DType.float64, self.N](0.0)
        for i in range(len(coeffs)):
            output += coeffs[i] * self.buffer[(self.index - i + len(self.buffer)) % len(self.buffer)]
        self.index = (self.index + 1) % len(self.buffer)
        return output


# struct FIR[N: Int = 1](Representable, Movable, Copyable):
#     var buffer: List[SIMD[DType.float64, N]]
#     var index: Int
#     var num_coeffs: Int

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_coeffs: Int):
#         self.buffer = [SIMD[DType.float64, self.N](0.0) for _ in range(num_coeffs)]
#         self.index = 0
#         self.num_coeffs = num_coeffs

#     fn __repr__(self) -> String:
#         return String("FIR")

#     fn next[simd_width: Int = 4](mut self, input: SIMD[DType.float64, self.N], coeffs: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
#         """SIMD-optimized FIR filter processing."""
        
#         # Update buffer
#         self.buffer[self.index] = input
        
#         var output: Float64 = 0.0
#         var num_chunks = self.num_coeffs // simd_width
#         var remainder = self.num_coeffs % simd_width
        
#         # Process SIMD chunks
#         for chunk in range(num_chunks):
#             var coeff_start = chunk * simd_width
            
#             # Load coefficients into SIMD vector
#             var coeffs_simd = SIMD[DType.float64, simd_width]()
#             for i in range(simd_width):
#                 coeffs_simd[i] = coeffs[coeff_start + i]
            
#             # Load buffer samples with circular indexing
#             var samples_simd = SIMD[DType.float64, simd_width]()
#             for i in range(simd_width):
#                 var buf_idx = (self.index - coeff_start - i + len(self.buffer)) % len(self.buffer)
#                 samples_simd[i] = self.buffer[buf_idx]
            
#             # SIMD multiply and accumulate
#             var products = coeffs_simd * samples_simd
            
#             # Horizontal sum (reduce)
#             for i in range(simd_width):
#                 output += products[i]
        
#         # Handle remaining coefficients
#         for i in range(remainder):
#             var coeff_idx = num_chunks * simd_width + i
#             var buf_idx = (self.index - coeff_idx + len(self.buffer)) % len(self.buffer)
#             output += coeffs[coeff_idx] * self.buffer[buf_idx]
        
#         # Update index
#         self.index = (self.index + 1) % len(self.buffer)
#         return output

struct IIR[N: Int = 1](Representable, Movable, Copyable):
    var fir1: FIR[N]
    var fir2: FIR[N]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.fir1 = FIR[N](world_ptr,2)
        self.fir2 = FIR[N](world_ptr,3)
        self.fb = SIMD[DType.float64, self.N](0.0)

    fn __repr__(self) -> String:
        return String("IIR")

    fn next(mut self: IIR, input: SIMD[DType.float64, self.N], coeffsbv: List[SIMD[DType.float64, self.N]], coeffsav: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
        var temp = input - self.fb
        # calls the parallelized fir function, indicating the size of the simd vector to use
        var output1 = self.fir1.next(temp, coeffsav)
        var output2 = self.fir2.next(temp, coeffsbv)
        self.fb = output1
        return output2

struct tf2[N: Int = 1](Representable, Movable, Copyable):
    var iir: IIR[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.iir = IIR[self.N](world_ptr)

    fn __repr__(self) -> String:
        return String("tf2")

    fn next(mut self: tf2, input: SIMD[DType.float64, self.N], coeffs: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
        return self.iir.next(input, coeffs[:3], coeffs[3:])


fn tf2s[N: Int = 1](coeffs: List[SIMD[DType.float64, N]], mut coeffs_out: List[SIMD[DType.float64, N]], sample_rate: Float64):
    var b2 = coeffs[0]
    var b1 = coeffs[1]
    var b0 = coeffs[2]
    var a1 = coeffs[3]
    var a0 = coeffs[4]
    var w1 = coeffs[5]

    var c   = 1/tan(w1*0.5/sample_rate) # bilinear-transform scale-factor
    var csq = c*c
    var d   = a0 + a1 * c + csq
    var b0d = (b0 + b1 * c + b2 * csq)/d
    var b1d = 2 * (b0 - b2 * csq)/d
    var b2d = (b0 - b1 * c + b2 * csq)/d
    var a1d = 2 * (a0 - csq)/d
    var a2d = (a0 - a1*c + csq)/d

    coeffs_out[0] = b0d
    coeffs_out[1] = b1d
    coeffs_out[2] = b2d
    coeffs_out[3] = a1d
    coeffs_out[4] = a2d

struct Reson[N: Int = 1](Representable, Movable, Copyable):
    var tf2: tf2[N]
    var coeffs: List[SIMD[DType.float64, N]]
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.tf2 = tf2[N](world_ptr)
        self.coeffs = [SIMD[DType.float64, self.N](0.0) for _ in range(5)]
        self.world_ptr = world_ptr

    fn __repr__(self) -> String:
        return String("Reson")

    fn lpf(mut self: Reson, input: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        var wc = 2*pi*freq
        var a1 = 1/q
        var a0 = SIMD[DType.float64, self.N](1.0)
        var b2 = SIMD[DType.float64, self.N](0.0)
        var b1 = SIMD[DType.float64, self.N](0.0)
        var b0 = SIMD[DType.float64, self.N](clip(gain, 0.0, 1.0))

        tf2s[self.N]([b2, b1, b0, a1, a0, wc], self.coeffs, self.world_ptr[0].sample_rate)

        return self.tf2.next(input, self.coeffs)

    fn hpf(mut self: Reson, input: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        var wc = 2*pi*freq
        var a1 = 1/q
        var a0 = SIMD[DType.float64, self.N](1.0)
        var b2 = SIMD[DType.float64, self.N](0.0)
        var b1 = SIMD[DType.float64, self.N](0.0)
        var b0 = SIMD[DType.float64, self.N](clip(gain, 0.0, 1.0))

        tf2s[self.N]([b2, b1, b0, a1, a0, wc], self.coeffs, self.world_ptr[0].sample_rate)

        return gain*input - self.tf2.next(input, self.coeffs)

    fn bpf(mut self: Reson, input: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        var wc = 2*pi*freq
        var a1 = 1/q
        var a0 = SIMD[DType.float64, self.N](1.0)
        var b2 = SIMD[DType.float64, self.N](0.0)
        var b1 = SIMD[DType.float64, self.N](clip(gain, 0.0, 1.0))
        var b0 = SIMD[DType.float64, self.N](0.0)

        tf2s[self.N]([b2, b1, b0, a1, a0, wc], self.coeffs, self.world_ptr[0].sample_rate)
        return self.tf2.next(input, self.coeffs)


# struct LBCF:
#     """JOS Lowpass Feedback Comb Filter"""

#     var world_ptr: UnsafePointer[MMMWorld]
#     var delay_line: List[Float64]
#     var delay_samples: Int64
#     var write_pos: Int64
#     var integrator_state: Float64
#     var mem_state: Float64
#     var 

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], mut delay_time: Float64):
#         self.world_ptr = world_ptr
#         if delay_time <= 0.0:
#             delay_time = 1.0 / world_ptr[0].sample_rate  # 1 sample minimum delay
#         self.delay_samples = Int64(delay_time * world_ptr[0].sample_rate)
#         self.fb_signal = 0.0
#         self.write_pos = 0
#         self.integrator_state = 0.0
#         self.mem_state = 0.0
        
#         # Initialize delay line
#         self.delay_line = [0.0 for _ in range(self.delay_samples + 1)]

#     fn next(mut self, input: Float64, feedback: Float64, damping: Float64) -> Float64:
#         # Read from delay line
        
#         # read from the sample that you are about to write into
#         delayed = self.delay_line[self.write_pos]

#         var sum_signal = input + delayed
        
#         self.integrator_state = sum_signal * (1.0 - damping) + (self.integrator_state * damping)
        
#         var feedback_signal = self.integrator_state * feedback
        
#         self.delay_line[self.write_pos] = feedback_signal
#         self.write_pos = (self.write_pos + 1) % (self.delay_samples + 1)
        
#         # mem: one sample delay
#         var output = self.mem_state
#         self.mem_state = sum_signal
        
#         return output