from .MMMWorld_Module import *
from math import exp, sqrt, tan, pi, tanh, ceil, floor
from bit import next_power_of_two
from .functions import *

from sys import simd_width_of
from algorithm import vectorize
from .Oversampling import Oversampling, Upsampler

struct Lag[num_chans: Int = 1](Representable, Movable, Copyable):
    """A lag processor that smooths input values over time based on a specified lag time in seconds.

    Parameters:
        num_chans: Number of SIMD channels to process in parallel.
    """

    comptime simd_width = simd_width_of[DType.float64]()
    var world: World
    var val: SIMD[DType.float64, Self.num_chans]
    var b1: SIMD[DType.float64, Self.num_chans]
    var lag: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self, world: World, lag: SIMD[DType.float64, Self.num_chans] = SIMD[DType.float64, Self.num_chans](0.02)):
        """Initialize the lag processor with given lag time in seconds.

        Args:
            world: Pointer to the MMMWorld.
            lag: SIMD vector specifying lag time in seconds for each channel.
        """
        
        self.world = world
        self.val = SIMD[DType.float64, Self.num_chans](0.0)
        self.b1 = 0
        self.lag = 0
        self.set_lag_time(lag)
        
    fn __repr__(self) -> String:
        return String("Lag")

    @always_inline
    fn next(mut self, in_samp: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the lag processor.
        
        Args:
            in_samp: Input SIMD vector values.
        
        Returns:
            Output values after applying the lag.
        """

        self.val = in_samp + self.b1 * (self.val - (in_samp))
        self.val = sanitize(self.val)

        return self.val

    @always_inline
    fn set_lag_time(mut self, lag: SIMD[DType.float64, Self.num_chans]):
        """Set a new lag time in seconds for each channel.
        
        Args:
            lag: SIMD vector specifying new lag time in seconds for each channel.
        """
        self.lag = lag
        self.b1 = exp(-6.907755278982137 / (lag * self.world[].sample_rate))
    
    @staticmethod
    fn par_process[num_simd: Int, simd_width: Int](mut lags: List[Lag[simd_width]], mut vals:List[MFloat[1]]):
        """Parallel processes a List[Lag[simd_width]]. The one dimensional list of vals is both the input and the output."""
        
        len_vals = len(vals)
        @parameter
        for i in range(num_simd):
            # process each lag group
            simd_val = SIMD[DType.float64, simd_width](0.0)
            for j in range(simd_width):
                idx = i * simd_width + j
                if idx < len_vals:
                    simd_val[j] = vals[idx]
            lagged_output = lags[i].next(simd_val)
            for j in range(simd_width):
                idx = i * simd_width + j
                if idx < len_vals:
                    vals[idx] = lagged_output[j]

@doc_private
struct SVFModes:
    """Enumeration of different State Variable Filter modes.

    This makes specifying a filter type more readable. For example,
    to specify a lowpass filter, use `SVFModes.lowpass`.

    | Mode     | Value |
    |----------|-------|
    | lowpass  | 0     |
    | bandpass | 1     |
    | highpass | 2     |
    | notch    | 3     |
    | peak     | 4     |
    | allpass  | 5     |
    | bell     | 6     |
    | lowshelf | 7     |
    | highshelf| 8     |
    """
    comptime lowpass: Int64 = 0
    comptime bandpass: Int64 = 1
    comptime highpass: Int64 = 2
    comptime notch: Int64 = 3
    comptime peak: Int64 = 4
    comptime allpass: Int64 = 5
    comptime bell: Int64 = 6
    comptime lowshelf: Int64 = 7
    comptime highshelf: Int64 = 8

struct SVF[num_chans: Int = 1](Representable, Movable, Copyable):
    """A State Variable Filter struct.

    To use the different modes, see the mode-specific methods.
    
    Implementation from [Andrew Simper](https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf). 
    Translated from Oleg Nesterov's Faust implementation.

    Parameters:
        num_chans: Number of SIMD channels to process in parallel.
    """

    var ic1eq: SIMD[DType.float64, Self.num_chans]  # Internal state 1
    var ic2eq: SIMD[DType.float64, Self.num_chans]  # Internal state 2
    var sample_rate: Float64
    
    fn __init__(out self, world: World):
        """Initialize the SVF.
        
        Args:
            world: Pointer to the MMMWorld.
        """
        self.ic1eq = SIMD[DType.float64, Self.num_chans](0.0)
        self.ic2eq = SIMD[DType.float64, Self.num_chans](0.0)
        self.sample_rate = world[].sample_rate

    fn __repr__(self) -> String:
        return String("SVF")

    fn reset(mut self):
        """Reset internal state of the filter."""
        self.ic1eq = SIMD[DType.float64, Self.num_chans](0.0)
        self.ic2eq = SIMD[DType.float64, Self.num_chans](0.0)

    @doc_private
    @always_inline
    fn _compute_coeficients[filter_type: Int64](self, frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans], gain_db: SIMD[DType.float64, Self.num_chans]) -> Tuple[SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans]]:
        """Compute filter coeficients based on type and parameters.
        
        Parameters:
            filter_type: The type of filter to compute coeficients for.

        Args:
            frequency: The cutoff/center frequency of the filter.
            q: The resonance (Q factor) of the filter.
            gain_db: The gain in decibels for filters that use it.

        Returns:
            A tuple containing (g, k, mix_a, mix_b, mix_c).
        """
        
        # Compute A (gain factor)
        var A: SIMD[DType.float64, Self.num_chans] = pow(SIMD[DType.float64, Self.num_chans](10.0), gain_db / 40.0)

        # Compute g (frequency warping)
        var base_g = tan(frequency * pi / self.sample_rate)
        var g: SIMD[DType.float64, Self.num_chans]
        @parameter
        if filter_type == 7:  # lowshelf
            g = base_g / sqrt(A)
        elif filter_type == 8:  # highshelf
            g = base_g * sqrt(A)
        else:
            g = base_g
        
        # Compute k (resonance factor)
        var k: SIMD[DType.float64, Self.num_chans]
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
    fn _get_mix_coeficients[filter_type: Int64](self, k: SIMD[DType.float64, Self.num_chans], A: SIMD[DType.float64, Self.num_chans]) -> Tuple[SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans]]:
        """Get mixing coeficients for different filter types"""
        
        mc0 = SIMD[DType.float64, Self.num_chans](1.0)
        mc1 = SIMD[DType.float64, Self.num_chans](0.0)
        mc2 = SIMD[DType.float64, Self.num_chans](0.0)

        @parameter
        for i in range(Self.num_chans):
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
    fn next[filter_type: Int64](mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans], gain_db: SIMD[DType.float64, Self.num_chans] = 0.0) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the SVF filter of the given type.
        
        Parameters:
            filter_type: The type of filter to apply. See `SVFModes` struct for options.

        Args:
            input: The next input value to process.
            frequency: The cutoff/center frequency of the filter.
            q: The resonance (Q factor) of the filter.
            gain_db: The gain in decibels for filters that use it.

        Returns:
            The next sample of the filtered output.
        """
        
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
    fn lpf(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF lowpass filter.
        
        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the lowpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next SIMD sample of the filtered output.
        """
        return self.next[SVFModes.lowpass](input, frequency, q)

    @always_inline
    fn bpf(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF bandpass filter.
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the bandpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.bandpass](input, frequency, q)

    @always_inline
    fn hpf(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF highpass filter.

        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the highpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.highpass](input, frequency, q)

    @always_inline
    fn notch(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF notch filter.
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the notch filter.
            q: The resonance (Q factor) of the filter.
        
        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.notch](input, frequency, q)

    @always_inline
    fn peak(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF peak filter.

        Args:
            input: The input signal to process.
            frequency: The center frequency of the peak filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.peak](input, frequency, q)

    @always_inline
    fn allpass(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF allpass filter.
        
        Args:
            input: The input signal to process.
            frequency: The center frequency of the allpass filter.
            q: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.allpass](input, frequency, q)

    @always_inline
    fn bell(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans], gain_db: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF bell filter (parametric EQ).
        
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
    fn lowshelf(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans], gain_db: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF low shelf filter.

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
    fn highshelf(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans], q: SIMD[DType.float64, Self.num_chans], gain_db: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """SVF high shelf filter.

        Args:
            input: The input signal to process.
            frequency: The cutoff frequency of the high shelf filter.
            q: The resonance (Q factor) of the filter.
            gain_db: The gain in decibels for the high shelf filter.

        Returns:
            The next sample of the filtered output.
        """
        return self.next[SVFModes.highshelf](input, frequency, q, gain_db)

struct lpf_LR4[num_chans: Int = 1](Representable, Movable, Copyable):
    """A 4th-order [Linkwitz-Riley](https://en.wikipedia.org/wiki/Linkwitz%E2%80%93Riley_filter) lowpass filter.

    Parameters:
        num_chans: Number of SIMD channels to process in parallel.
    """
    var svf1: SVF[Self.num_chans]
    var svf2: SVF[Self.num_chans]
    var q: Float64


    fn __init__(out self, world: World):
        """Initialize the 4th-order Linkwitz-Riley lowpass filter.
        
        Args:
            world: Pointer to the MMMWorld.
        """
        self.svf1 = SVF[Self.num_chans](world)
        self.svf2 = SVF[Self.num_chans](world)
        self.q = 1.0 / sqrt(2.0)  # 1/sqrt(2) for Butterworth response

    fn __repr__(self) -> String:
        return String("lpf_LR4")

    @always_inline
    fn next(mut self, input: SIMD[DType.float64, Self.num_chans], frequency: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
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

struct OnePole[num_chans: Int = 1](Representable, Movable, Copyable):
    """One-pole IIR filter that can be configured as lowpass or highpass.

    Parameters:
        num_chans: Number of channels to process in parallel.
    """
    var last_samp: SIMD[DType.float64, Self.num_chans]  # Previous output
    var world: World
    
    fn __init__(out self, world: World):
        """Initialize the one-pole filter."""

        self.last_samp = SIMD[DType.float64, Self.num_chans](0.0)
        self.world = world
    
    fn __repr__(self) -> String:
        return String("OnePoleFilter")

    @doc_private
    fn next(mut self, input: SIMD[DType.float64, Self.num_chans], coef: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the filter.

        Args:
            input: The input signal to process.
            coef: The filter coefficient.

        Returns:
            The next sample of the filtered output.
        """
        coef2 = clip(coef, -0.999999, 0.999999)
        var output = (1 - abs(coef2)) * input + coef2 * self.last_samp
        self.last_samp = output
        return output

    fn lpf(mut self, input: SIMD[DType.float64, Self.num_chans], cutoff_hz: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the one-pole lowpass filter with a given cutoff frequency.

        Args:
            input: The input signal to process.
            cutoff_hz: The cutoff frequency of the lowpass filter.

        Returns:
            The next sample of the filtered output.
        """
        var coef = self.coeff(cutoff_hz)
        return self.next(input, coef)

    fn hpf(mut self, input: SIMD[DType.float64, Self.num_chans], cutoff_hz: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the one-pole highpass filter with a given cutoff frequency.

        Args:
            input: The input signal to process.
            cutoff_hz: The cutoff frequency of the highpass filter.

        Returns:
            The next sample of the filtered output.
        """
        var coef = self.coeff(cutoff_hz)
        return self.next(input, -coef)

    @doc_private
    fn coeff(self, cutoff_hz: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Calculate feedback coefficient from cutoff frequency."""
        return exp(-2.0 * pi * cutoff_hz / self.world[].sample_rate)


# struct Integrator(Representable, Movable, Copyable):
#     """
#     Simple one-pole IIR filter that can be configured as lowpass or highpass
#     """
#     var last_samp: Float64  # Previous output
#     var sample_rate: Float64
    
#     fn __init__(out self, world: World):
#         self.last_samp = 0.0
#         self.sample_rate = world[].sample_rate
    
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
    
#     fn __init__(out self, world: World):
#         """Initialize the one-zero filter"""

#         self.last_samp = 0.0
#         self.sample_rate = world[].sample_rate
    
#     fn __repr__(self) -> String:
#         return String("OnePoleFilter")
    
#     fn next(mut self, input: Float64, coef: Float64) -> Float64:
#         """Process one sample through the filter"""
#         var output = input - coef * self.last_samp
#         self.last_samp = output
#         return output

struct DCTrap[num_chans: Int=1](Movable, Copyable):
    """DC Trap filter.
    
    Implementation from Digital Sound Generation by Beat Frei. The cutoff
    frequency of the highpass filter is fixed to 5 Hz.

    Parameters:
        num_chans: Number of channels to process in parallel.
    """

    var alpha: Float64
    var last_samp: SIMD[DType.float64, Self.num_chans]
    var last_inner: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self, world: World):
        """Initialize the DC blocker filter.
        
        Args:
            world: Pointer to the MMMWorld.
        """
        self.alpha = 2 * pi * 5.0 / world[].sample_rate  # 5 Hz cutoff frequency
        self.last_samp = SIMD[DType.float64, Self.num_chans](0.0)
        self.last_inner = SIMD[DType.float64, Self.num_chans](0.0)

    fn next(mut self, input: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
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

struct VAOnePole[num_chans: Int = 1](Representable, Movable, Copyable):
    """
    One-pole filter based on the Virtual Analog design by 
    Vadim Zavalishin in "The Art of VA Filter Design".
    
    This implementation supports both lowpass and highpass modes.

    Parameters:
        num_chans: Number of channels to process in parallel.
    """

    var last_1: SIMD[DType.float64, Self.num_chans]  # Previous output
    var step_val: Float64

    fn __init__(out self, world: World):
        """Initialize the VAOnePole filter.

        Args:
            world: Pointer to the MMMWorld.
        """
        self.last_1 = SIMD[DType.float64, Self.num_chans](0.0)
        self.step_val = 1.0 / world[].sample_rate

    fn __repr__(self) -> String:
        return String(
            "VAOnePole"
        )

    @always_inline
    fn lpf(mut self, input: SIMD[DType.float64, Self.num_chans], freq: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
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
    fn hpf(mut self, input: SIMD[DType.float64, Self.num_chans], freq: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the VA one-pole highpass filter.

        Args:
            input: The input signal to process.
            freq: The cutoff frequency of the highpass filter.
        
        Returns:
            The next sample of the filtered output.
        """
        return input - self.lpf(input, freq)

struct VAMoogLadder[num_chans: Int = 1, os_index: Int = 0](Representable, Movable, Copyable):
    """Virtual Analog Moog Ladder Filter.
    
    Implementation based on the Virtual Analog design by Vadim Zavalishin in 
    "The Art of VA Filter Design"

    This implementation supports 4-pole lowpass filtering with optional [oversampling](Oversampling.md).

    Parameters:
        num_chans: Number of channels to process in parallel.
        os_index: [oversampling](Oversampling.md) factor as a power of two (0 = no oversampling, 1 = 2x, 2 = 4x, etc).
    """
    var nyquist: Float64
    var step_val: Float64
    var last_1: SIMD[DType.float64, Self.num_chans]
    var last_2: SIMD[DType.float64, Self.num_chans]
    var last_3: SIMD[DType.float64, Self.num_chans]
    var last_4: SIMD[DType.float64, Self.num_chans]
    var oversampling: Oversampling[Self.num_chans, 2 ** Self.os_index]
    var upsampler: Upsampler[Self.num_chans, 2 ** Self.os_index]

    fn __init__(out self, world: World):
        """Initialize the VAMoogLadder filter.

        Args:
            world: Pointer to the MMMWorld.
        """
        self.nyquist = world[].sample_rate * 0.5 * (2 ** Self.os_index)
        self.step_val = 1.0 / self.nyquist
        self.last_1 = SIMD[DType.float64, Self.num_chans](0.0)
        self.last_2 = SIMD[DType.float64, Self.num_chans](0.0)
        self.last_3 = SIMD[DType.float64, Self.num_chans](0.0)
        self.last_4 = SIMD[DType.float64, Self.num_chans](0.0)
        self.oversampling = Oversampling[Self.num_chans, 2 ** Self.os_index](world)
        self.upsampler = Upsampler[Self.num_chans, 2 ** Self.os_index](world)


    fn __repr__(self) -> String:
        return String("VAMoogLadder")

    @doc_private
    @always_inline
    fn lp4(mut self, sig: SIMD[DType.float64, Self.num_chans], freq: SIMD[DType.float64, Self.num_chans], q_val: SIMD[DType.float64, Self.num_chans]) -> SIMD[DType.float64, Self.num_chans]:
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
        mask1: SIMD[DType.bool, Self.num_chans] = s4.gt(2.0)
        mask2: SIMD[DType.bool, Self.num_chans] = s4.lt(-2.0)

        s4 = mask1.select(
            tanh(s4 - 1.0) + 1.0,
            mask2.select(tanh(s4 + 1.0) - 1.0, s4))

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
    fn next(mut self, sig: SIMD[DType.float64, Self.num_chans], freq: SIMD[DType.float64, Self.num_chans] = 100, q_val: SIMD[DType.float64, Self.num_chans] = 0.5) -> SIMD[DType.float64, Self.num_chans]:
        """Process one sample through the Moog Ladder lowpass filter.

        Args:
            sig: The input signal to process.
            freq: The cutoff frequency of the lowpass filter.
            q_val: The resonance (Q factor) of the filter.

        Returns:
            The next sample of the filtered output.
        """
        
        @parameter
        if Self.os_index == 0:
            return self.lp4(sig, freq, q_val)
        else:
            comptime times_oversampling = 2 ** Self.os_index

            @parameter
            for i in range(times_oversampling):
                # upsample the input
                sig2 = self.upsampler.next(sig, i)

                var lp4 = self.lp4(sig2, freq, q_val)
                @parameter
                if Self.os_index == 0:
                    return lp4
                else:
                    self.oversampling.add_sample(lp4)
            return self.oversampling.get_sample()

struct Reson[num_chans: Int = 1](Movable, Copyable):
    """Resonant filter with lowpass, highpass, and bandpass modes.

    A translation of Julius Smith's Faust implementation of [tf2s (virtual analog) resonant filters](https://github.com/grame-cncm/faustlibraries/blob/6061da8bf2279ae4281333861a3dc6254e9076f9/filters.lib#L2054).
    Copyright (C) 2003-2019 by Julius O. Smith III

    Parameters:
        num_chans: Number of SIMD channels to process in parallel.
    """
    var tf2: tf2[num_chans = Self.num_chans]
    var coeffs: List[MFloat[Self.num_chans]]
    var sample_rate: Float64

    fn __init__(out self, world: World):
        """Initialize the Reson filter.

        Args:
            world: Pointer to the MMMWorld.
        """
        self.tf2 = tf2[num_chans = Self.num_chans](world)
        self.coeffs = [MFloat[Self.num_chans](0.0) for _ in range(5)]
        self.sample_rate = world[].sample_rate

    @doc_private
    @always_inline
    fn tf2s(mut self, b2: SIMD[DType.float64, Self.num_chans], b1: SIMD[DType.float64, Self.num_chans], b0: SIMD[DType.float64, self.num_chans], a1: SIMD[DType.float64, Self.num_chans], a0: SIMD[DType.float64, Self.num_chans], w1: SIMD[DType.float64, Self.num_chans], sample_rate: Float64) -> Tuple[SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans], SIMD[DType.float64, Self.num_chans]]:
        var c   = 1/tan(w1*0.5/sample_rate) # bilinear-transform scale-factor
        var csq = c*c
        var d   = a0 + a1 * c + csq
        var b0d = (b0 + b1 * c + b2 * csq)/d
        var b1d = 2 * (b0 - b2 * csq)/d
        var b2d = (b0 - b1 * c + b2 * csq)/d
        var a1d = 2 * (a0 - csq)/d
        var a2d = (a0 - a1*c + csq)/d

        return (b0d, b1d, b2d, a1d, a2d)

    @always_inline
    fn lpf(mut self, input: MFloat[self.num_chans], freq: MFloat[self.num_chans], q: MFloat[self.num_chans], gain: MFloat[self.num_chans]) -> MFloat[self.num_chans]:
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
        var a0 = 1.0
        var b2 = 0.0
        var b1 = 0.0
        var b0 = clip(gain, 0.0, 1.0)

        b0d, b1d, b2d, a1d, a2d = self.tf2s(b2, b1, b0, a1, a0, wc, self.sample_rate)

        return self.tf2.next(input, b0d, b1d, b2d, a1d, a2d)

    @always_inline
    fn hpf(mut self, input: MFloat[self.num_chans], freq: MFloat[self.num_chans], q: MFloat[self.num_chans], gain: MFloat[self.num_chans]) -> MFloat[self.num_chans]:
        """Process input through a resonant highpass filter.

        Args:
            input: The input signal to process.
            freq: The cutoff frequency of the highpass filter.
            q: The resonance (Q factor) of the filter.
            gain: The output gain (clipped to 0.0-1.0 range).

        Returns:
            The next sample of the filtered output.
        """

        return gain*input - self.lpf(input, freq, q, gain)

    @always_inline
    fn bpf(mut self, input: MFloat[self.num_chans], freq: MFloat[self.num_chans], q: MFloat[self.num_chans], gain: MFloat[self.num_chans]) -> MFloat[self.num_chans]:
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
        var a0 = 1.0
        var b2 = 0.0
        var b1 = clip(gain, 0.0, 1.0)
        var b0 = 0.0

        b0d, b1d, b2d, a1d, a2d = self.tf2s(b2, b1, b0, a1, a0, wc, self.sample_rate)

        return self.tf2.next(input, b0d, b1d, b2d, a1d, a2d)

@doc_private
struct FIR[num_chans: Int = 1](Representable, Movable, Copyable):
    """Finite Impulse Response (FIR) filter implementation.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III

    Parameters:
        num_chans: The number of SIMD channels to process.
    """

    var buffer: List[MFloat[Self.num_chans]]
    var index: Int

    fn __init__(out self, world: World, num_coeffs: Int):
        """Initialize the FIR.

        Args:
            world: Pointer to the MMMWorld.
            num_coeffs: The number of filter coefficients.
        """
        self.buffer = [MFloat[Self.num_chans](0.0) for _ in range(num_coeffs)]
        self.index = 0

    fn __repr__(self) -> String:
        return String("FIR")

    @always_inline
    fn next(mut self: FIR, input: MFloat[self.num_chans], *coeffs: MFloat[self.num_chans]) -> MFloat[self.num_chans]:
        """Compute the next output sample of the FIR filter.

        Args:
            input: The input signal to process.
            coeffs: The filter coefficients.

        Returns:
            The next sample of the filtered output.
        """
        self.buffer[self.index] = input
        var output = MFloat[self.num_chans](0.0)
        for i in range(len(coeffs)):
            output += coeffs[i] * self.buffer[(self.index - i + len(self.buffer)) % len(self.buffer)]
        self.index = (self.index + 1) % len(self.buffer)
        return output

@doc_private
struct IIR[num_chans: Int = 1](Movable, Copyable):
    """Infinite Impulse Response (IIR) filter implementation.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III

    Parameters:
        num_chans: The number of SIMD channels to process.
    """
    var fir1: FIR[Self.num_chans]
    var fir2: FIR[Self.num_chans]
    var fb: MFloat[Self.num_chans]

    fn __init__(out self, world: World):
        """Initialize the IIR.

        Args:
            world: Pointer to the MMMWorld.
        """
        self.fir1 = FIR[Self.num_chans](world,2)
        self.fir2 = FIR[Self.num_chans](world,3)
        self.fb = MFloat[Self.num_chans](0.0)

    @always_inline
    fn next(mut self: IIR, input: MFloat[self.num_chans], *coeffs: MFloat[self.num_chans]) -> MFloat[self.num_chans]:
        """Compute the next output sample of the IIR filter.
        
        Args:
            input: The input signal to process.
            coeffs: The filter coefficients.
            
        Returns:
            The next sample of the filtered output.
        """
        var temp = input - self.fb
        # calls the parallelized fir function, indicating the size of the simd vector to use
        var output1 = self.fir1.next(temp, coeffs[3], coeffs[4])
        var output2 = self.fir2.next(temp, coeffs[0], coeffs[1], coeffs[2])
        self.fb = output1
        return output2

@doc_private
struct tf2[num_chans: Int = 1](Representable, Movable, Copyable):
    """Second-order transfer function filter implementation.

    A translation of Julius Smith's Faust implementation of digital filters.
    Copyright (C) 2003-2019 by Julius O. Smith III

    Parameters:
        num_chans: The number of SIMD channels to process.
    """
    var iir: IIR[Self.num_chans]

    fn __init__(out self, world: World):
        """Initialize the tf2 filter.

        Args:
            world: Pointer to the MMMWorld.
        """
        self.iir = IIR[Self.num_chans](world)

    fn __repr__(self) -> String:
        return String("tf2")

    @always_inline
    fn next(mut self: tf2, input: MFloat[self.num_chans], b0d: MFloat[self.num_chans], b1d: MFloat[self.num_chans], b2d: MFloat[self.num_chans], a1d: MFloat[self.num_chans], a2d: MFloat[self.num_chans]) -> MFloat[self.num_chans]:
        """Process one sample through the second-order transfer function filter.

        Args:
            input: The input signal to process.
            b0d: The b0 coefficient.
            b1d: The b1 coefficient.
            b2d: The b2 coefficient.
            a1d: The a1 coefficient.
            a2d: The a2 coefficient.

        Returns:
            The next sample of the filtered output.
        """
        return self.iir.next(input, b0d, b1d, b2d, a1d, a2d)

