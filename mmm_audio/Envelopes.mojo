"""Envelope generator module.

This module provides an envelope generator class that can create complex envelopes with multiple segments, curves, and looping capabilities.
"""

from .Oscillators import Sweep
from .MMMWorld_Module import *
from .functions import *
from .RisingBoolDetector_Module import RisingBoolDetector

struct EnvParams(Representable, Movable, Copyable):
    """Parameters for the Env class.

    This struct holds the parameters for the envelope generator. It
    is not required to use the `Env` struct, but it might be convenient.


    Elements:
    
    values: List of envelope values at each breakpoint.  
    times: List of durations (in seconds) for each segment between adjacent breakpoints. This List should be one element shorter than the `values` List.  
    curves: List of curve shapes for each segment. Positive values for convex "exponential" curves, negative for concave "logarithmic" curves. (if the output of the envelope is negative, the curve will be inverted).  
    loop: Bool to indicate if the envelope should loop.  
    time_warp: Time warp factor to speed up or slow down the envelope. Default is 1.0 meaning no warp. A value of 2.0 will make the envelop take twice as long to complete. A value of 0.5 will make the envelope take half as long to complete.
    """

    var values: List[Float64]
    var times: List[Float64]
    var curves: List[Float64]
    var loop: Bool
    var time_warp: Float64

    fn __init__(out self, values: List[Float64] = List[Float64](0,1,0), times: List[Float64] = List[Float64](1,1), curves: List[Float64] = List[Float64](1), loop: Bool = False, time_warp: Float64 = 1.0):
        """Initialize EnvParams.

        For information on the arguments, see the documentation of the `Env::next()` method that takes each parameter individually.
        """
        
        self.values = values.copy()  # Make a copy to avoid external modifications
        self.times = times.copy()
        self.curves = curves.copy()
        self.loop = loop
        self.time_warp = time_warp

    fn __repr__(self) -> String:
        return String("EnvParams")

struct Env(Representable, Movable, Copyable):
    """Envelope generator with an arbitrary number of segments."""

    var sweep: Sweep  # Sweep for tracking time
    var rising_bool_detector: RisingBoolDetector  # Track the last trigger state
    var is_active: Bool  # Flag to indicate if the envelope is active
    var times: List[Float64]  # List of segment durations
    var dur: Float64  # Total duration of the envelope
    var freq: Float64  # Frequency multiplier for the envelope
    var trig_point: Float64  # Point at which the asr envelope was triggered
    var last_asr: Float64  # Last output of the asr envelope

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        """Initialize the Env struct.

        Args:
            world: Pointer to the MMMWorld.
        """

        self.sweep = Sweep(world)
        self.rising_bool_detector = RisingBoolDetector()  # Initialize rising bool detector
        self.is_active = False
        self.times = List[Float64]()  # Initialize times list
        self.dur = 0.0  # Initialize total duration
        self.freq = 0.0
        self.trig_point = 0.0
        self.last_asr = 0.0

    fn __repr__(self) -> String:
        return String("Env")

    @doc_private
    fn reset_vals(mut self, times: List[Float64]):
        """Reset internal values."""

        if self.times.__len__() != (times.__len__() + 1):
            self.times.clear()
        while self.times.__len__() < (times.__len__() + 1):
            self.times.insert(0, 0.0)  # Ensure times list has the same length as the input times
        for i in range(times.__len__()):
            self.times[i+1] = self.times[i] + times[i]  # Copy values from input times

        self.dur = self.times[-1]  # Set total duration to the last value in times
        if self.dur > 0.0:
            self.freq = 1.0 / self.dur
        else:
            self.freq = 0.0

    fn next(mut self: Env, ref values: List[Float64], ref times: List[Float64] = List[Float64](1,1), ref curves: List[Float64] = List[Float64](1), loop: Bool = False, trig: Bool = True, time_warp: Float64 = 1.0) -> Float64:
         """Generate the next envelope value.
            
            Args:
                values: List of envelope values at each breakpoint.
                times: List of durations (in seconds) for each segment between adjacent breakpoints. This List should be one element shorter than the `values` List.
                curves: List of curve shapes for each segment. Positive values for convex "exponential" curves, negative for concave "logarithmic" curves. (if the output of the envelope is negative, the curve will be inverted)
                loop: Bool to indicate if the envelope should loop.
                trig: Trigger to start the envelope.
                time_warp: Time warp factor to speed up or slow down the envelope. Default is 1.0 meaning no warp. A value of 2.0 will make the envelop take twice as long to complete. A value of 0.5 will make the envelope take half as long to complete.
        """
        phase = 0.0
        if not self.is_active:
            if self.rising_bool_detector.next(trig):
                self.sweep.phase = 0.0  # Reset phase on trigger
                self.is_active = True  # Start the envelope
                self.reset_vals(times)
            else:
                return values[0]
        else:
            if self.rising_bool_detector.next(trig):
                self.sweep.phase = 0.0  # Reset phase on trigger
                self.reset_vals(times)
            else:    
                phase = self.sweep.next(self.freq / time_warp)

        if loop and phase >= 1.0:  # Check if the envelope has completed
            self.sweep.phase = 0.0  # Reset phase for looping
            phase = 0.0
        elif not loop and phase >= 1.0: 
            if values[-1]==values[0]:
                self.is_active = False  # Stop the envelope if not looping and last value is the same as first
                return values[0]  # Return the first value if not looping
            else:
                return values[-1]  # Return the last value if not looping

        phase = phase * self.dur

        # Find the current segment
        var segment = 0
        while segment < len(self.times) - 1 and phase >= self.times[segment + 1]:
            segment += 1
            

        if values[segment] == values[segment + 1]:
            out = values[segment]
        elif values[segment] < values[segment + 1]:
            out = lincurve(phase, self.times[segment], self.times[segment + 1], values[segment], values[segment + 1], curves[segment % len(curves)])
        else:
            out = lincurve(phase, self.times[segment], self.times[segment + 1], values[segment], values[segment + 1], -1 * curves[segment % len(curves)])

        return out
    
    fn next(mut self, ref params: EnvParams, trig: Bool = True) -> Float64:
        """Generate the next envelope value.
        
        Args:
            params: An EnvParams containing the parameters for the envelope. For information on the parameters see the other Env::next() method that takes each parameter individually.
            trig: Trigger to start the envelope.
        """
        return self.next(params.values, params.times, params.curves, params.loop, trig, params.time_warp)

# min_env is just a function, not a struct
fn min_env[N: Int = 1](phase: SIMD[DType.float64, N] = 0.01, totaldur: SIMD[DType.float64, N] = 0.1, rampdur: SIMD[DType.float64, N] = 0.001) -> SIMD[DType.float64, N]:
    """Simple envelope.

    Envelope that rises linearly from 0 to 1 over `rampdur` seconds, stays at 1 until `totaldur - rampdur`, 
    then falls linearly back to 0 over the final `rampdur` seconds. This envelope isn't "triggered," instead
    the user provides the current phase between 0 (beginning) and 1 (end) of the envelope.

    Args:
        phase: Current env position between 0 (beginning) and 1 (end).
        totaldur: Total duration of the envelope.
        rampdur: Duration of the rise and fall segments that occur at the beginning and end of the envelope.

    Returns:
        Envelope value at the current ramp position.
    """
    
    # Pre-compute common values
    rise_ratio = rampdur / totaldur
    fall_threshold = 1.0 - rise_ratio
    dur_over_rise = totaldur / rampdur
    
    # Create condition masks
    in_attack: SIMD[DType.bool, N] = phase < rise_ratio
    in_release: SIMD[DType.bool, N] = phase > fall_threshold
    
    # Compute envelope values for each segment
    attack_value = phase * dur_over_rise
    release_value = (1.0 - phase) * dur_over_rise
    sustain_value = SIMD[DType.float64, N](1.0)
    
    # Use select to choose the appropriate value
    return in_attack.select(attack_value,
           in_release.select(release_value, sustain_value))

struct ASREnv(Representable, Movable, Copyable):
    """Simple ASR envelope generator."""
    var sweep: Sweep  # Sweep for tracking time
    var bool_changed: Changed  # Track the last trigger state
    var freq: Float64  # Frequency for the envelope

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        """Initialize the ASREnv struct.
        
        Args:
            world: Pointer to the MMMWorld.
        """
        self.sweep = Sweep(world)
        self.bool_changed = Changed()  # Initialize last trigger state
        self.freq = 0.0  # Initialize frequency

    fn __repr__(self) -> String:
        return String("ASREnv")
    
    fn next(mut self, attack: Float64, sustain: Float64, release: Float64, gate: Bool, curve: SIMD[DType.float64, 2] = 1) -> Float64:
        """Simple ASR envelope generator.
        
        Args:
            attack: (Float64): Attack time in seconds.
            sustain: (Float64): Sustain level (0 to 1).
            release: (Float64): Release time in seconds.
            gate: (Bool): Gate signal (True or False).
            curve: (SIMD[DType.float64, 2]): Can pass a Float64 for equivalent curve on rise and fall or SIMD[DType.float64, 2] for different rise and fall curve. Positive values for convex "exponential" curves, negative for concave "logarithmic" curves.
        """

        if self.bool_changed.next(gate):
            if gate:
                self.freq = 1.0 / attack
            else:
                self.freq = -1.0 / release

        _ = self.sweep.next(self.freq, gate)
        self.sweep.phase = clip(self.sweep.phase, 0.0, 1.0)

        if gate:
            return lincurve(self.sweep.phase, 0.0, 1.0, 0.0, sustain, curve[0])
        else:
            return lincurve(self.sweep.phase, 0.0, 1.0, 0.0, sustain, curve[1])