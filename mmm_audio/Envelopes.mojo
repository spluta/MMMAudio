"""Envelope generator module.

This module provides an envelope generator class that can create complex envelopes with multiple segments, curves, and looping capabilities.
"""

from mmm_audio import *

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

    fn __init__(out self, values: List[Float64] = [0,1,0], times: List[Float64] = [1,1], curves: List[Float64] = [1], loop: Bool = False, time_warp: Float64 = 1.0):
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

    var sweep: Sweep[1]  # Sweep for tracking time
    var rising_bool_detector: RisingBoolDetector[1]  # Track the last trigger state
    var is_active: Bool  # Flag to indicate if the envelope is active
    var times: List[Float64]  # List of segment durations
    var dur: Float64  # Total duration of the envelope
    var freq: Float64  # Frequency multiplier for the envelope
    var trig_point: Float64  # Point at which the asr envelope was triggered
    var last_asr: Float64  # Last output of the asr envelope
    var params: EnvParams

    fn __init__(out self, world: World):
        """Initialize the Env2 struct - with internal params.

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
        self.params = EnvParams()
        self.params.values=[0,1,0]
        self.params.times=[1,1]
        self.reset_vals()

    fn __repr__(self) -> String:
        return String("Env")

    @doc_private
    fn reset_vals(mut self):
        """Reset internal values."""

        if self.times.__len__() != (self.params.times.__len__() + 1):
            self.times.clear()
        while self.times.__len__() < (self.params.times.__len__() + 1):
            self.times.insert(0, 0.0)  # Ensure times list has the same length as the input times
        for i in range(self.params.times.__len__()):
            self.times[i+1] = self.times[i] + self.params.times[i]  # Copy values from input times

        self.dur = self.times[-1]  # Set total duration to the last value in times
        if self.dur > 0.0:
            self.freq = 1.0 / self.dur
        else:
            self.freq = 0.0

    fn next(mut self, trig: Bool = True) -> Float64:
         """Generate the next envelope value. Uses the internal `params` struct for envelope parameters. See `EnvParams` for more details on the parameters.
            
            Args:
                trig: Trigger to start the envelope.
            
            Returns:
                The next envelope value.
        """
        phase = 0.0
        if not self.is_active:
            if self.rising_bool_detector.next(trig):
                self.sweep.phase = 0.0  # Reset phase on trigger
                self.is_active = True  # Start the envelope
                self.reset_vals()
            else:
                return self.params.values[0]
        else:
            if self.rising_bool_detector.next(trig):
                self.sweep.phase = 0.0  # Reset phase on trigger
                self.reset_vals()
            else:    
                phase = self.sweep.next(self.freq / self.params.time_warp)

        if self.params.loop and phase >= 1.0:  # Check if the envelope has completed
            self.sweep.phase = 0.0  # Reset phase for looping
            phase = 0.0
        elif not self.params.loop and phase >= 1.0: 
            if self.params.values[-1]==self.params.values[0]:
                self.is_active = False  # Stop the envelope if not looping and last value is the same as first
                return self.params.values[0]  # Return the first value if not looping
            else:
                return self.params.values[-1]  # Return the last value if not looping

        return self.apply_phase(phase)

    fn next(mut self, trig: Bool, phase: MFloat[1]) -> MFloat[1]:
        """Generate the next envelope value with a provided phase rather than using the internal phasor. Uses the internal `params` struct for envelope parameters. See `EnvParams` for more details on the parameters.
            
            Args:
                trig: Trigger to start the envelope.
                phase: The current phase of the envelope, between 0 and 1. This allows the user to control the progression of the envelope externally rather than using the internal phasor.
            
            Returns:
                The envelope value at the specified phase.
        """
        if self.rising_bool_detector.next(trig):
            self.reset_vals()
        if phase >= 1.0:
            return self.params.values[-1]
        return self.apply_phase(phase)

    @doc_private
    fn apply_phase(mut self, phase: MFloat[1]) -> MFloat[1]:
        var segment = 0
        phase2 = phase * self.dur
        while segment < len(self.times) - 1 and phase2 >= self.times[segment + 1]:
            segment += 1

        # by the above logic, segment should never be able to be the last index of times or values 
        out = lincurve(phase2, self.times[segment], self.times[segment + 1], self.params.values[segment], self.params.values[segment + 1], self.params.curves[segment % len(self.params.curves)])
        return out

    fn get_phase(self) -> Float64:
        """Get the current phase of the envelope (between 0 and 1)."""
        return clip(self.sweep.phase, 0.0, 1.0)
    


# min_env is just a function, not a struct
fn min_env[N: Int = 1](phase: MFloat[N] = 0.01, totaldur: MFloat[N] = 0.1, rampdur: MFloat[N] = 0.001) -> MFloat[N]:
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
    in_attack: MBool[N] = phase < rise_ratio
    in_release: MBool[N] = phase > fall_threshold
    
    # Compute envelope values for each segment
    attack_value = phase * dur_over_rise
    release_value = (1.0 - phase) * dur_over_rise
    sustain_value = MFloat[N](1.0)
    
    # Use select to choose the appropriate value
    return in_attack.select(attack_value,
           in_release.select(release_value, sustain_value))

struct ASREnv(Movable, Copyable):
    """Simple ASR envelope generator."""
    var sweep: Sweep[1] 
    var bool_changed: Changed[Bool]
    var freq: Float64 
    var is_active: Bool  

    fn __init__(out self, world: World):
        """Initialize the ASREnv struct.
        
        Args:
            world: Pointer to the MMMWorld.
        """
        self.sweep = Sweep(world)
        self.bool_changed = Changed(False) 
        self.freq = 0.0  
        self.is_active = False

    fn next(mut self, attack: Float64, sustain: Float64, release: Float64, gate: Bool, curve: MFloat[2] = 1) -> Float64:
        """Simple ASR envelope generator.
        
        Args:
            attack: (Float64): Attack time in seconds.
            sustain: (Float64): Sustain level (0 to 1).
            release: (Float64): Release time in seconds.
            gate: (Bool): Gate signal (True or False).
            curve: (MFloat[2]): Can pass a Float64 for equivalent curve on rise and fall or MFloat[2] for different rise and fall curve. Positive values for convex "exponential" curves, negative for concave "logarithmic" curves.
        """

        if self.bool_changed.next(gate):
            if gate:
                self.is_active = True
                self.freq = 1.0 / attack
            else:
                self.freq = -1.0 / release

        _ = self.sweep.next(self.freq, gate)
        
        self.sweep.phase = clip(self.sweep.phase, 0.0, 1.0)
        self.is_active = self.sweep.phase > 0.0 or gate

        if gate:
            return lincurve(self.sweep.phase, 0.0, 1.0, 0.0, sustain, curve[0])
        else:
            return lincurve(self.sweep.phase, 0.0, 1.0, 0.0, sustain, curve[1])