from mmm_src.MMMWorld import MMMWorld
from math import exp, sqrt, tan, pi, tanh, ceil, floor
from bit import next_power_of_two
from mmm_utils.functions import *

from sys import simd_width_of
from algorithm import vectorize
from .Oversampling import Oversampling

from mmm_src.MMMTraits import *

struct Lag[N: Int = 1](Representable, Movable, Copyable):
    """A lag processor that smooths input values over time based on a specified lag time in seconds.

    Parameters:
        N: Number of SIMD channels to process in parallel.
    """

    alias simd_width = simd_width_of[DType.float64]()
    var world_ptr: UnsafePointer[MMMWorld]
    var val: SIMD[DType.float64, N]
    var b1: SIMD[DType.float64, N]
    var lag: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], lag: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.02)):
        """Initialize the lag processor with given lag time in seconds.

        Args:
            world_ptr: Pointer to the MMMWorld.
            lag: SIMD vector specifying lag time in seconds for each channel.

        Returns:
            None.
        """
        
        self.world_ptr = world_ptr
        self.val = SIMD[DType.float64, self.N](0.0)
        self.b1 = exp(-6.907755278982137 / (lag * self.world_ptr[0].sample_rate))
        self.lag = lag
        
    fn __repr__(self) -> String:
        return String("Lag")

    @always_inline
    fn next(mut self, in_samp: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """
        Process one sample through the lag processor.
        
        Args:
            in_samp: (SIMD[DType.float64, N]): Input SIMD vector of Float64 values.
        
        Returns:
            SIMD[DType.float64, N]: Output SIMD vector of Float64 values after applying the lag.
        """

        self.val = in_samp + self.b1 * (self.val - (in_samp))
        self.val = sanitize(self.val)

        return self.val

    @always_inline
    fn set_lag_time(mut self, lag: SIMD[DType.float64, self.N]):
        """Set a new lag time in seconds for each channel.
        
        Args:
            lag: SIMD vector specifying new lag time in seconds for each channel.
        
        Returns:
            None.
        """
        self.lag = lag
        self.b1 = exp(-6.907755278982137 / (lag * self.world_ptr[0].sample_rate))

alias simd_width = simd_width_of[DType.float64]() * 2

struct LagN[lag: Float64 = 0.02, N: Int = 1](Movable, Copyable):
    var list: List[Lag[simd_width]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], lag_times: List[Float64]):

        alias num_simd = N // simd_width + (0 if N % simd_width == 0 else 1)
        self.list = [Lag[simd_width](world_ptr, lag_times[i%N]) for i in range(num_simd)]

    @always_inline
    fn next(mut self, ref in_list: List[Float64], mut out_list: List[Float64]):
        vals = SIMD[DType.float64, simd_width](0.0)
        N = len(out_list)
        in_len = len(in_list)

        @parameter
        fn closure[width: Int](i: Int):
            if i + simd_width <= in_len:
                vals = in_list.unsafe_ptr().load[width=simd_width](i)
            else:
                @parameter
                for j in range(simd_width):
                    vals[j] = in_list[(j + i) % in_len]

            temp = self.list[i // simd_width].next(vals)
            # More efficient storing
            remaining = N - i
            if remaining >= simd_width:
                out_list.unsafe_ptr().store(i, temp)
            else:
                # Handle partial store for the last chunk
                @parameter
                for j in range(simd_width):
                    if j < remaining:
                        out_list[i + j] = temp[j]
        vectorize[closure, simd_width](N)

struct SVFModes:
    alias lowpass: Int64 = 0
    alias bandpass: Int64 = 1
    alias highpass: Int64 = 2
    alias notch: Int64 = 3
    alias peak: Int64 = 4
    alias allpass: Int64 = 5
    alias bell: Int64 = 6
    alias lowshelf: Int64 = 7
    alias highshelf: Int64 = 8

struct SVF[N: Int = 1](Representable, Movable, Copyable):
    """State Variable Filter
    
    Implementation from 
    [Andrew Simper](https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf). 
    Translated from Oleg Nesterov's Faust implementation.

    This struct enables many different types of filters (see below). To use any of them,
    they are all declared and initialized in the same way. Use the
    "convenience" functions for calling the different filter types. For example to 
    create a lowpass filter:

    ```mojo
    # declare
    var svf: SVF
    ```
    ...
    ```mojo
    # initialize
    self.svf = SVF(world_ptr)
    ```
    ...
    ```mojo
    # use
    output = self.svf.lpf(input,1000.0, 1.0)  # lowpass filter
    ```

    Parameters:
        N: Number of SIMD channels to process in parallel.
    """

    var ic1eq: SIMD[DType.float64, N]  # Internal state 1
    var ic2eq: SIMD[DType.float64, N]  # Internal state 2
    var sample_rate: Float64
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the SVF.
        
        Args:
            world_ptr: Pointer to the MMMWorld.

        Returns:
            None
        """
        self.ic1eq = SIMD[DType.float64, N](0.0)
        self.ic2eq = SIMD[DType.float64, N](0.0)
        self.sample_rate = world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String("SVF")

    fn reset(mut self):
        """Reset internal state
        
        Args:
            None

        Returns:
            None
        """
        self.ic1eq = SIMD[DType.float64, N](0.0)
        self.ic2eq = SIMD[DType.float64, N](0.0)

    @doc_private
    @always_inline
    fn _compute_coeficients[filter_type: Int64](self, frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> (SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N]):
        """Compute filter coeficients based on type and parameters"""
        
        # Compute A (gain factor)
        var A: SIMD[DType.float64, self.N] = pow(SIMD[DType.float64, self.N](10.0), gain_db / 40.0)

        # Compute g (frequency warping)
        var base_g = tan(frequency * pi / self.sample_rate)
        var g: SIMD[DType.float64, self.N]
        @parameter
        if filter_type == 7:  # lowshelf
            g = base_g / sqrt(A)
        elif filter_type == 8:  # highshelf
            g = base_g * sqrt(A)
        else:
            g = base_g
        
        # Compute k (resonance factor)
        var k: SIMD[DType.float64, self.N]
        @parameter
        if filter_type == 6:  # bell
            k = 1.0 / (q * A)
        else:
            k = 1.0 / q
        
        # Get mix coeficients based on filter type
        var mix_coefs = self._get_mix_coeficients[filter_type](k, A)
        
        return (g, k, mix_coefs[0], mix_coefs[1], mix_coefs[2])

    @doc_private
    @always_inline
    fn _get_mix_coeficients[filter_type: Int64](self, k: SIMD[DType.float64, N], A: SIMD[DType.float64, self.N]) -> (SIMD[DType.float64, self.N], SIMD[DType.float64, self.N], SIMD[DType.float64, self.N]):
        """Get mixing coeficients for different filter types"""
        
        mc0 = SIMD[DType.float64, self.N](1.0)
        mc1 = SIMD[DType.float64, self.N](0.0)
        mc2 = SIMD[DType.float64, self.N](0.0)

        @parameter
        for i in range(self.N):
            @parameter
            if filter_type == SVFModes.lowpass:    
                mc0[i], mc1[i], mc2[i] = 0.0, 0.0, 1.0
            elif filter_type == SVFModes.bandpass:  
                mc0[i], mc1[i], mc2[i] = 0.0, 1.0, 0.0
            elif filter_type == SVFModes.highpass:   
                mc0[i], mc1[i], mc2[i] = 1.0, -k[i], -1.0
            elif filter_type == SVFModes.notch:   
                mc0[i], mc1[i], mc2[i] = 1.0, -k[i], 0.0
            elif filter_type == SVFModes.peak:   
                mc0[i], mc1[i], mc2[i] = 1.0, -k[i], -2.0
            elif filter_type == SVFModes.allpass:   
                mc0[i], mc1[i], mc2[i] = 1.0, -2.0*k[i], 0.0
            elif filter_type == SVFModes.bell:  
                mc0[i], mc1[i], mc2[i] = 1.0, k[i]*(A[i]*A[i] - 1.0), 0.0
            elif filter_type == SVFModes.lowshelf:   
                mc0[i], mc1[i], mc2[i] = 1.0, k[i]*(A[i] - 1.0), A[i]*A[i] - 1.0
            elif filter_type == SVFModes.highshelf:    
                mc0[i], mc1[i], mc2[i] = A[i]*A[i], k[i]*(1.0 - A[i])*A[i], 1.0 - A[i]*A[i]
            else:
                mc0[i], mc1[i], mc2[i] = 1.0, 0.0, 0.0  

        return (mc0, mc1, mc2)

    @doc_private
    @always_inline
    fn next[filter_type: Int64](mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N] = 0.0) -> SIMD[DType.float64, self.N]:
        """Process one sample through the SVF filter of the given type."""
        
        var coefs = self._compute_coeficients[filter_type](frequency, q, gain_db)
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

        self.ic1eq = sanitize(self.ic1eq)
        self.ic2eq = sanitize(self.ic2eq)
        
        # Mix the outputs: mix_a*v0 + mix_b*v1 + mix_c*v2
        var output = mix_a * input + mix_b * v1 + mix_c * v2
        return sanitize(output)
    
    @always_inline
    fn lpf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Lowpass filter
        
        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the lowpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.lowpass](input, frequency, q)

    @always_inline
    fn bpf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Bandpass filter
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the bandpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.bandpass](input, frequency, q)

    @always_inline
    fn hpf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Highpass filter

        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the highpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.highpass](input, frequency, q)

    @always_inline
    fn notch(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Notch filter
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the notch filter.
            q: The resonance (Q factor) of the filter.
        
        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.notch](input, frequency, q)

    @always_inline
    fn peak(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Peak filter

        Args:
            input: The input signal to process.
            frequency: The center frequency of the peak filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.peak](input, frequency, q)

    @always_inline
    fn allpass(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Allpass filter
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the allpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.allpass](input, frequency, q)

    @always_inline
    fn bell(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Bell filter (parametric EQ)
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the bell filter.
            q: The resonance (Q factor) of the filter.
            gain_db: The gain in decibels for the bell filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.bell](input, frequency, q, gain_db)

    @always_inline
    fn lowshelf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Low shelf filter

        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the low shelf filter.
            q: The resonance (Q factor) of the filter.
            gain_db: The gain in decibels for the low shelf filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.lowshelf](input, frequency, q, gain_db)

    @always_inline
    fn highshelf(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain_db: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """High shelf filter

        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the high shelf filter.
            q: The resonance (Q factor) of the filter.
            gain_db: The gain in decibels for the high shelf filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.highshelf](input, frequency, q, gain_db)

struct lpf_LR4[N: Int = 1](Representable, Movable, Copyable):
    """A 4th-order [Linkwitz-Riley](https://en.wikipedia.org/wiki/Linkwitz%E2%80%93Riley_filter) lowpass filter.

    Linkwitz-Riley filters are commonly used for 
    audio crossovers because they have a flat magnitude
    response when combining a high pass and low pass
    at the same cutoff frequency.

    Parameters:
        N: Number of SIMD channels to process in parallel.
    """
    var svf1: SVF[N]
    var svf2: SVF[N]
    var q: Float64


    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the 4th-order Linkwitz-Riley lowpass filter
        
        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.svf1 = SVF[self.N](world_ptr)
        self.svf2 = SVF[self.N](world_ptr)
        self.q = 1.0 / sqrt(2.0)  # 1/sqrt(2) for Butterworth response

    fn __repr__(self) -> String:
        return String("lpf_LR4")

    fn set_sample_rate(mut self, sample_rate: Float64):
        self.svf1.sample_rate = sample_rate
        self.svf2.sample_rate = sample_rate

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, self.N], frequency: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """A single sample through the 4th order Linkwitz-Riley lowpass filter.
        
        Args:
            input: The input sample to process.
            frequency: The cutoff frequency of the lowpass filter.

        Returns:
            The next sample of the filtered output.
        """
        # First stage
        var cf = self.svf1.lpf(input, frequency, self.q)  # First stage
        # Second stage
        return self.svf2.lpf(cf, frequency, self.q)  # Second stage

struct OnePole[N: Int = 1](Representable, Movable, Copyable):
    """
    Simple one-pole IIR filter that can be configured as lowpass or highpass.

    Parameters:
        N: Number of channels to process in parallel.
    """
    var last_samp: SIMD[DType.float64, N]  # Previous output
    
    fn __init__(out self):
        """Initialize the one-pole filter"""

        self.last_samp = SIMD[DType.float64, N](0.0)
    
    fn __repr__(self) -> String:
        return String("OnePoleFilter")

    fn next(mut self, input: SIMD[DType.float64, N], coef: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        """Process one sample through the filter

        Args:
            input: The input signal to process. Can be a SIMD vector for parallel processing.
            coef: The filter coefficient.

        Returns:
            The filtered output signal. Will be a SIMD vector if input is SIMD, otherwise a Float64.
        """
        coef2 = clip(coef, -0.999999, 0.999999)
        var output = (1 - abs(coef2)) * input + coef2 * self.last_samp
        self.last_samp = output
        return output


# struct Integrator(Representable, Movable, Copyable):
#     """
#     Simple one-pole IIR filter that can be configured as lowpass or highpass
#     """
#     var last_samp: Float64  # Previous output
#     var sample_rate: Float64
    
#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         self.last_samp = 0.0
#         self.sample_rate = world_ptr[0].sample_rate
    
#     fn __repr__(self) -> String:
#         return String("Integrator")
    
#     fn next(mut self, input: Float64, coef: Float64) -> Float64:
#         """Process one sample through the filter"""
#         var output = input + coef * self.last_samp
#         self.last_samp = output
#         return output

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

    Parameters:
        N: Number of channels to process in parallel.
    """

    var alpha: Float64
    var last_samp: SIMD[DType.float64, N]
    var last_inner: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the DC blocker filter.
        
        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.alpha = 2 * pi * 5.0 / world_ptr[0].sample_rate  # 5 Hz cutoff frequency
        self.last_samp = SIMD[DType.float64, N](0.0)
        self.last_inner = SIMD[DType.float64, N](0.0)

    fn __repr__(self) -> String:
        return String("DCBlockerFilter")

    fn next(mut self, input: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        """Process one sample through the DC blocker filter.
        
        Args:
            input: The input signal to process.

        Returns:
            The next sample of the filtered output.
        """
        self.last_inner = self.last_samp * self.alpha + self.last_inner

        sample = input - self.last_inner
        self.last_samp = sample

        return sample

struct VAOnePole[N: Int = 1](Representable, Movable, Copyable):
    """
    One-pole filter based on the Virtual Analog design by 
    Vadim Zavalishin in "The Art of VA Filter Design"
    
    This implementation supports both lowpass and highpass modes.

    Parameters:
        N: Number of channels to process in parallel.
    """

    var last_1: SIMD[DType.float64, N]  # Previous output
    var step_val: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the VAOnePole filter.

        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.last_1 = SIMD[DType.float64, N](0.0)
        self.step_val = 1.0 / world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String(
            "VAOnePole"
        )

    @always_inline
    fn lpf(mut self, input: SIMD[DType.float64, N], freq: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        """Process one sample through the VA one-pole lowpass filter.

        Args:
            input: The input signal to process.
            freq: The cutoff frequency of the lowpass filter.
        
        Returns:
            The next sample of the filtered output.
        """

        var g =  tan(pi * freq * self.step_val)

        var G = g / (1.0 + g)

        var v = (input - self.last_1) * G

        var output = self.last_1 + v
        self.last_1 = v + output
        return output

    @always_inline
    fn hpf(mut self, input: SIMD[DType.float64, N], freq: SIMD[DType.float64, N]) -> SIMD[DType.float64, N]:
        """Process one sample through the VA one-pole highpass filter.

        Args:
            input: The input signal to process.
            freq: The cutoff frequency of the highpass filter.
        
        Returns:
            The next sample of the filtered output.
        """
        return input - self.lpf(input, freq)

struct VAMoogLadder[N: Int = 1, os_index: Int = 0](Representable, Movable, Copyable):
    """Virtual Analog Moog Ladder Filter.
    
    Implementation based on the Virtual Analog design by Vadim Zavalishin in 
    "The Art of VA Filter Design"

    This implementation supports 4-pole lowpass filtering with optional oversampling.

    Parameters:
        N: Number of channels to process in parallel.
        os_index: Oversampling factor as a power of two (0 = no oversampling, 1 = 2x, 2 = 4x, etc.)
    """
    var nyquist: Float64
    var step_val: Float64
    var last_1: SIMD[DType.float64, N]
    var last_2: SIMD[DType.float64, N]
    var last_3: SIMD[DType.float64, N]
    var last_4: SIMD[DType.float64, N]
    var oversampling: Oversampling[N, 2 ** os_index]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the VAMoogLadder filter.

        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.nyquist = world_ptr[0].sample_rate * 0.5
        self.step_val = 1.0 / world_ptr[0].sample_rate
        self.last_1 = SIMD[DType.float64, N](0.0)
        self.last_2 = SIMD[DType.float64, N](0.0)
        self.last_3 = SIMD[DType.float64, N](0.0)
        self.last_4 = SIMD[DType.float64, N](0.0)
        self.oversampling = Oversampling[self.N, 2 ** os_index](world_ptr)

    fn __repr__(self) -> String:
        return String(
            "VAMoogLadder"
        )

    @doc_private
    @always_inline
    fn lp4(mut self, sig: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q_val: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process one sample through the 4-pole Moog Ladder lowpass filter.

        Args:
            sig: The input signal to process.
            freq: The cutoff frequency of the lowpass filter.
            q_val: The resonance (Q factor) of the filter.
        
        Returns:
            The next sample of the filtered output.
        """
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

        return lp4

    @always_inline
    fn next(mut self, sig: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q_val: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process one sample through the Moog Ladder lowpass filter with optional oversampling.

        Args:
            sig: The input signal to process.
            freq: The cutoff frequency of the lowpass filter.
            q_val: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        
        @parameter
        if os_index == 0:
            return self.lp4(sig, freq, q_val)
        else:
            alias times_oversampling = 2 ** os_index

            @parameter
            for _ in range(times_oversampling):
                var lp4 = self.lp4(sig, freq, q_val)
                @parameter
                if os_index == 0:
                    return lp4
                else:
                    self.oversampling.add_sample(lp4)
            return self.oversampling.get_sample()

struct Reson[N: Int = 1](Representable, Movable, Copyable):
    """Resonant filter with lowpass, highpass, and bandpass modes.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>

    Parameters:
        N: Number of SIMD channels to process in parallel.
    """
    var tf2: tf2[N]
    var coeffs: List[SIMD[DType.float64, N]]
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the Reson filter.

        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.tf2 = tf2[N](world_ptr)
        self.coeffs = [SIMD[DType.float64, self.N](0.0) for _ in range(5)]
        self.world_ptr = world_ptr

    fn __repr__(self) -> String:
        return String("Reson")

    @always_inline
    fn lpf(mut self: Reson, input: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process input through a resonant lowpass filter.

        Args:
            input: The input signal to process.
            freq: The cutoff frequency of the lowpass filter.
            q: The resonance (Q factor) of the filter.
            gain: The output gain (clipped to 0.0-1.0 range).

        Returns:
            The next sample of the filtered output.
        """
        var wc = 2*pi*freq
        var a1 = 1/q
        var a0 = SIMD[DType.float64, self.N](1.0)
        var b2 = SIMD[DType.float64, self.N](0.0)
        var b1 = SIMD[DType.float64, self.N](0.0)
        var b0 = SIMD[DType.float64, self.N](clip(gain, 0.0, 1.0))

        tf2s[self.N]([b2, b1, b0, a1, a0, wc], self.coeffs, self.world_ptr[0].sample_rate)

        return self.tf2.next(input, self.coeffs)

    @always_inline
    fn hpf(mut self: Reson, input: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process input through a resonant highpass filter.

        Args:
            input: The input signal to process.
            freq: The cutoff frequency of the highpass filter.
            q: The resonance (Q factor) of the filter.
            gain: The output gain (clipped to 0.0-1.0 range).

        Returns:
            The next sample of the filtered output.
        """
        var wc = 2*pi*freq
        var a1 = 1/q
        var a0 = SIMD[DType.float64, self.N](1.0)
        var b2 = SIMD[DType.float64, self.N](0.0)
        var b1 = SIMD[DType.float64, self.N](0.0)
        var b0 = SIMD[DType.float64, self.N](clip(gain, 0.0, 1.0))

        tf2s[self.N]([b2, b1, b0, a1, a0, wc], self.coeffs, self.world_ptr[0].sample_rate)

        return gain*input - self.tf2.next(input, self.coeffs)

    @always_inline
    fn bpf(mut self: Reson, input: SIMD[DType.float64, self.N], freq: SIMD[DType.float64, self.N], q: SIMD[DType.float64, self.N], gain: SIMD[DType.float64, self.N]) -> SIMD[DType.float64, self.N]:
        """Process input through a resonant bandpass filter.

        Args:
            input: The input signal to process.
            freq: The center frequency of the bandpass filter.
            q: The resonance (Q factor) of the filter.
            gain: The output gain (clipped to 0.0-1.0 range).

        Returns:
            The next sample of the filtered output.
        """
        var wc = 2*pi*freq
        var a1 = 1/q
        var a0 = SIMD[DType.float64, self.N](1.0)
        var b2 = SIMD[DType.float64, self.N](0.0)
        var b1 = SIMD[DType.float64, self.N](clip(gain, 0.0, 1.0))
        var b0 = SIMD[DType.float64, self.N](0.0)

        tf2s[self.N]([b2, b1, b0, a1, a0, wc], self.coeffs, self.world_ptr[0].sample_rate)
        return self.tf2.next(input, self.coeffs)

struct FIR[N: Int = 1](Representable, Movable, Copyable):
    """Finite Impulse Response (FIR) filter implementation.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>

    Parameters:
        N: The number of SIMD channels to process.
    """

    var buffer: List[SIMD[DType.float64, N]]
    var index: Int

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_coeffs: Int):
        """Initialize the FIR.

        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.buffer = [SIMD[DType.float64, N](0.0) for _ in range(num_coeffs)]
        self.index = 0

    fn __repr__(self) -> String:
        return String("FIR")

    @always_inline
    fn next(mut self: FIR, input: SIMD[DType.float64, self.N], coeffs: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
        """Compute the next output sample of the FIR filter.

        Args:
            input: The input signal to process.
            coeffs: The filter coefficients.

        Returns:
            The next sample of the filtered output.
        """
        self.buffer[self.index] = input
        var output = SIMD[DType.float64, self.N](0.0)
        for i in range(len(coeffs)):
            output += coeffs[i] * self.buffer[(self.index - i + len(self.buffer)) % len(self.buffer)]
        self.index = (self.index + 1) % len(self.buffer)
        return output


# struct FIR[N: Int = 1](Representable, Movable, Copyable):
#     """A translation of Julius Smith's Faust implementation of digital filters.
#     Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>
#     """

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
    """Infinite Impulse Response (IIR) filter implementation.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>

    Parameters:
        N: The number of SIMD channels to process.
    """
    var fir1: FIR[N]
    var fir2: FIR[N]
    var fb: SIMD[DType.float64, N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the IIR.

        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.fir1 = FIR[N](world_ptr,2)
        self.fir2 = FIR[N](world_ptr,3)
        self.fb = SIMD[DType.float64, self.N](0.0)

    fn __repr__(self) -> String:
        return String("IIR")

    @always_inline
    fn next(mut self: IIR, input: SIMD[DType.float64, self.N], coeffsbv: List[SIMD[DType.float64, self.N]], coeffsav: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
        """Compute the next output sample of the IIR filter.
        
        Args:
            input: The input signal to process.
            coeffsbv: The 'b' coefficients of the IIR filter.
            coeffsav: The 'a' coefficients of the IIR filter.
        """
        var temp = input - self.fb
        # calls the parallelized fir function, indicating the size of the simd vector to use
        var output1 = self.fir1.next(temp, coeffsav)
        var output2 = self.fir2.next(temp, coeffsbv)
        self.fb = output1
        return output2

struct tf2[N: Int = 1](Representable, Movable, Copyable):
    """Second-order transfer function filter implementation.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>

    Parameters:
        N: The number of SIMD channels to process.
    """
    var iir: IIR[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the tf2 filter.

        Args:
            world_ptr: Pointer to the MMMWorld.
        """
        self.iir = IIR[self.N](world_ptr)

    fn __repr__(self) -> String:
        return String("tf2")

    @always_inline
    fn next(mut self: tf2, input: SIMD[DType.float64, self.N], coeffs: List[SIMD[DType.float64, self.N]]) -> SIMD[DType.float64, self.N]:
        """Process one sample through the second-order transfer function filter.

        Args:
            input: The input signal to process.
            coeffs: List of filter coefficients.

        Returns:
            The next sample of the filtered output.
        """
        return self.iir.next(input, coeffs[:3], coeffs[3:])

@always_inline
fn tf2s[N: Int = 1](coeffs: List[SIMD[DType.float64, N]], mut coeffs_out: List[SIMD[DType.float64, N]], sample_rate: Float64):
    """

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III <jos@ccrma.stanford.edu>

    Parameters:
        N: The number of SIMD channels to process.

    Args:
        coeffs: List containing analog coefficients [b2, b1, b0, a1, a0, w1] where
                b coefficients are numerator, a coefficients are denominator,
                and w1 is the angular frequency.
        coeffs_out: Output list for digital coefficients [b0d, b1d, b2d, a1d, a2d].
        sample_rate: The sample rate in Hz.

    Returns:
        None. Results are stored in coeffs_out.
    """
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