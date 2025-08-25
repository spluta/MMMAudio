from mmm_src.MMMWorld import MMMWorld
from math import exp, sqrt, tan, pi, tanh
from mmm_utils.functions import *

struct Lag(Representable, Movable, Copyable):
    var val: Float64
    var b1: Float64
    var lag: Float64
    var log001: Float64
    var world_ptr: UnsafePointer[MMMWorld]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.val = 0.0
        self.b1 = 0.0
        self.lag = 0.0
        self.world_ptr = world_ptr
        self.log001 = -6.907755278982137  # log(0.01) for lag calculations, precomputed for efficiency

    fn __repr__(self) -> String:
        return String("Lag")

    fn next(mut self: Lag, in_samp: Float64, lag: Float64) -> Float64:

        var val = self.val
        var b1 = self.b1

        if lag == self.lag:
            val = in_samp + b1 * (val - in_samp)
        else:
            if lag == 0.0:
                b1 = 0.0
            else:
                # Calculate the lag coeficient based on the sample rate
                b1 = exp(self.log001 / (lag * self.world_ptr[0].sample_rate))

            self.lag = lag
            val = in_samp + b1 * (val - in_samp)
            self.b1 = b1

        self.val = zapgremlins(val)

        return self.val

struct SVF(Representable, Movable, Copyable):
    """State Variable Filter implementation translated from Oleg Nesterov's Faust implementation"""
    
    var ic1eq: Float64  # Internal state 1
    var ic2eq: Float64  # Internal state 2
    var sample_rate: Float64
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the SVF with given sample rate"""
        self.ic1eq = 0.0
        self.ic2eq = 0.0
        self.sample_rate = world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String("SVF")

    fn reset(mut self):
        """Reset internal state"""
        self.ic1eq = 0.0
        self.ic2eq = 0.0
    
    fn _compute_coeficients(self, filter_type: Int, frequency: Float64, q: Float64, gain_db: Float64) -> (Float64, Float64, Float64, Float64, Float64):
        """Compute filter coeficients based on type and parameters"""
        
        # Compute A (gain factor)
        var A: Float64 = pow(10.0, gain_db / 40.0)

        # Compute g (frequency warping)
        var base_g = tan(frequency * pi / self.sample_rate)
        var g: Float64
        if filter_type == 7:  # lowshelf
            g = base_g / sqrt(A)
        elif filter_type == 8:  # highshelf
            g = base_g * sqrt(A)
        else:
            g = base_g
        
        # Compute k (resonance factor)
        var k: Float64
        if filter_type == 6:  # bell
            k = 1.0 / (q * A)
        else:
            k = 1.0 / q
        
        # Get mix coeficients based on filter type
        var mix_coefs = self._get_mix_coeficients(filter_type, k, A)
        
        return (g, k, mix_coefs[0], mix_coefs[1], mix_coefs[2])
    
    fn _get_mix_coeficients(self, filter_type: Int, k: Float64, A: Float64) -> (Float64, Float64, Float64):
        """Get mixing coeficients for different filter types"""
        
        if filter_type == 0:      # lowpass
            return (0.0, 0.0, 1.0)
        elif filter_type == 1:    # bandpass
            return (0.0, 1.0, 0.0)
        elif filter_type == 2:    # highpass
            return (1.0, -k, -1.0)
        elif filter_type == 3:    # notch
            return (1.0, -k, 0.0)
        elif filter_type == 4:    # peak
            return (1.0, -k, -2.0)
        elif filter_type == 5:    # allpass
            return (1.0, -2.0*k, 0.0)
        elif filter_type == 6:    # bell
            return (1.0, k*(A*A - 1.0), 0.0)
        elif filter_type == 7:    # lowshelf
            return (1.0, k*(A - 1.0), A*A - 1.0)
        elif filter_type == 8:    # highshelf
            return (A*A, k*(1.0 - A)*A, 1.0 - A*A)
        else:
            return (1.0, 0.0, 0.0)  # default
    
    fn next(mut self, input: Float64, filter_type: Int, frequency: Float64, q: Float64, gain_db: Float64 = 0.0) -> Float64:
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
        var new_ic1eq = 2.0 * v1 - self.ic1eq
        var new_ic2eq = 2.0 * v2 - self.ic2eq
        
        self.ic1eq = new_ic1eq
        self.ic2eq = new_ic2eq
        
        # Mix the outputs: mix_a*v0 + mix_b*v1 + mix_c*v2
        return mix_a * input + mix_b * v1 + mix_c * v2
    
    # Convenience methods for different filter types
    fn lpf(mut self, input: Float64, frequency: Float64, q: Float64) -> Float64:
        """Lowpass filter"""
        return self.next(input, 0, frequency, q)
    
    fn bpf(mut self, input: Float64, frequency: Float64, q: Float64) -> Float64:
        """Bandpass filter"""
        return self.next(input, 1, frequency, q)
    
    fn hpf(mut self, input: Float64, frequency: Float64, q: Float64) -> Float64:
        """Highpass filter"""
        return self.next(input, 2, frequency, q)
    
    fn notch(mut self, input: Float64, frequency: Float64, q: Float64) -> Float64:
        """Notch filter"""
        return self.next(input, 3, frequency, q)
    
    fn peak(mut self, input: Float64, frequency: Float64, q: Float64) -> Float64:
        """Peak filter"""
        return self.next(input, 4, frequency, q)
    
    fn allpass(mut self, input: Float64, frequency: Float64, q: Float64) -> Float64:
        """Allpass filter"""
        return self.next(input, 5, frequency, q)
    
    fn bell(mut self, input: Float64, frequency: Float64, q: Float64, gain_db: Float64) -> Float64:
        """Bell filter (parametric EQ)"""
        return self.next(input, 6, frequency, q, gain_db)
    
    fn lowshelf(mut self, input: Float64, frequency: Float64, q: Float64, gain_db: Float64) -> Float64:
        """Low shelf filter"""
        return self.next(input, 7, frequency, q, gain_db)
    
    fn highshelf(mut self, input: Float64, frequency: Float64, q: Float64, gain_db: Float64) -> Float64:
        """High shelf filter"""
        return self.next(input, 8, frequency, q, gain_db)

struct lpf_LR4(Representable, Movable, Copyable):
    var svf1: SVF
    var svf2: SVF
    var sample_rate: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.svf1 = SVF(world_ptr)
        self.svf2 = SVF(world_ptr)
        self.sample_rate = world_ptr[0].sample_rate  # Initialize sample rate from the MMMWorld instance

    fn __repr__(self) -> String:
        return String("lpf_LR4")

    fn next(mut self, input: Float64, frequency: Float64) -> Float64:
        """Next a single sample through the 4th order lowpass filter"""
        # First stage
        var cf = self.svf1.lpf(input, frequency, 1 / sqrt(2.0))  # First stage
        # Second stage
        return self.svf2.lpf(cf, frequency, 1 / sqrt(2.0))  # Second stage

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


struct OneZero(Representable, Movable, Copyable):
    """
    Simple one-zero filter
    """
    var last_samp: Float64  # Previous output
    var sample_rate: Float64
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the one-zero filter"""

        self.last_samp = 0.0
        self.sample_rate = world_ptr[0].sample_rate
    
    fn __repr__(self) -> String:
        return String("OnePoleFilter")
    
    fn next(mut self, input: Float64, coef: Float64) -> Float64:
        """Process one sample through the filter"""
        var output = input - coef * self.last_samp
        self.last_samp = output
        return output

struct DCTrap(Representable, Movable, Copyable):
    """DC Trap from Digital Sound Generation by Beat Frei.

    Arguments:
        input: The input signal to process.
    """

    var alpha: Float64
    var last_samp: Float64
    var last_inner: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the DC blocker filter"""
        self.alpha = 2 * pi * 5.0 / world_ptr[0].sample_rate  # 5 Hz cutoff frequency
        self.last_samp = 0.0
        self.last_inner = 0.0

    fn __repr__(self) -> String:
        return String("DCBlockerFilter")
    
    fn next(mut self, input: Float64) -> Float64:
        """Process one sample through the DC blocker filter"""
        var out = self.last_samp * self.alpha + self.last_inner
        
        self.last_inner = out

        out = input - out
        self.last_samp = out

        return out

struct VAOnePole(Representable, Movable, Copyable):
    """
    Simple one-pole IIR filter that can be configured as lowpass or highpass}
    """

    var last_1: Float64  # Previous output
    var step_val: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.last_1 = 0.0
        self.step_val = 1.0 / world_ptr[0].sample_rate

    fn __repr__(self) -> String:
        return String(
            "VAOnePole"
        )

    fn lpf(mut self, input: Float64, freq: Float64) -> Float64:
        """Process one sample through the filter"""

        # var omegaWarp = tan(pi * cf * self.step_val)
        # var g = omegaWarp / (1.0 + omegaWarp)
        var g =  tan(pi * freq * self.step_val)

        var G = g / (1.0 + g)

        var v = (input - self.last_1) * G

        var output = self.last_1 + v
        self.last_1 = v + output
        return output

    fn hpf(mut self, input: Float64, freq: Float64) -> Float64:
        return input - self.lpf(input, freq)

struct VAMoogLadder(Representable, Movable, Copyable):
    var nyquist: Float64
    var step_val: Float64
    var last_1: Float64
    var last_2: Float64
    var last_3: Float64
    var last_4: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.nyquist = world_ptr[0].sample_rate * 0.5
        self.step_val = 1.0 / world_ptr[0].sample_rate
        self.last_1 = 0.0
        self.last_2 = 0.0
        self.last_3 = 0.0
        self.last_4 = 0.0

    fn __repr__(self) -> String:
        return String(
            "VAMoogLadder"
        )

    fn next(mut self, sig: Float64, freq: Float64, q_val: Float64) -> Float64:
        var cf = clip(freq, 0.0, self.nyquist * 0.6)
        
        # k is the feedback coefficient of the entire circuit
        var k = 4.0 * q_val
        
        var omegaWarp = tan(pi * cf * self.step_val)
        var g = omegaWarp / (1.0 + omegaWarp)
        
        var g4 = g * g * g * g
        var s4 = g * g * g * (self.last_1 * (1 - g)) + g * g * (self.last_2 * (1 - g)) + g * (self.last_3 * (1 - g)) + (self.last_4 * (1 - g))
        
        # internally clips the feedback signal to prevent the filter from blowing up
        if s4 > 1.0:
            s4 = tanh(s4 - 1.0) + 1.0
        elif s4 < -2.0:
            s4 = tanh(s4 + 1.0) - 1.0
        
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
        
        # var v1 = g * (input - self.last_1)
        # var lp1 = self.last_1 + v1
        
        # var v2 = g * (lp1 - self.last_2)
        # var lp2 = self.last_2 + v2
        
        # var v3 = g * (lp2 - self.last_3)
        # var lp3 = self.last_3 + v3
        
        # var v4 = g * (lp3 - self.last_4)
        # var lp4 = self.last_4 + v4
        
        self.last_1 = lp1
        self.last_2 = lp2
        self.last_3 = lp3
        self.last_4 = lp4
        
        return lp4
