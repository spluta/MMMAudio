"""Envelope generator module.

This module provides an envelope generator class that can create complex envelopes with multiple segments, curves, and looping capabilities.
"""

from .Osc import Sweep
from .Filters import Lag
from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_utils.RisingBoolDetector import RisingBoolDetector

struct EnvParams(Representable, Movable, Copyable):
    """
    Parameters for the Env class.
    This struct holds the values, times, curves, loop flag, and time warp factor for the envelope generator.
    
    Attributes:
        values (List[Float64]): List of envelope values at each segment.
        times (List[Float64]): List of durations for each segment.
        curves (List[Float64]): List of curve shapes for each segment.
        loop (Bool): Flag to indicate if the envelope should loop.
        time_warp (Float64): Time warp factor to speed up or slow down the envelope.
    """

    var values: List[Float64]
    var times: List[Float64]
    var curves: List[Float64]
    var loop: Bool
    var time_warp: Float64

    fn __init__(out self, values: List[Float64] = List[Float64](1,1), times: List[Float64] = List[Float64](1,1), curves: List[Float64] = List[Float64](1), loop: Bool = False, time_warp: Float64 = 1.0):
        self.values = values.copy()  # Make a copy to avoid external modifications
        self.times = times.copy()
        self.curves = curves.copy()
        self.loop = loop
        self.time_warp = time_warp

    fn __repr__(self) -> String:
        return String("EnvParams")

struct Env(Representable, Movable, Copyable):
    """Envelope generator."""

    var sweep: Sweep  # Sweep for tracking time
    var rising_bool_detector: RisingBoolDetector  # Track the last trigger state
    var is_active: Bool  # Flag to indicate if the envelope is active
    var times: List[Float64]  # List of segment durations
    var dur: Float64  # Total duration of the envelope
    var freq: Float64  # Frequency multiplier for the envelope
    var last_out: Float64  # Last output value of the envelope
    var Lag: Lag  # Lag filter for smoothing the envelope output

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):

        self.sweep = Sweep(world_ptr)
        self.rising_bool_detector = RisingBoolDetector()  # Initialize rising bool detector
        self.is_active = False
        self.times = List[Float64]()  # Initialize times list
        self.dur = 0.0  # Initialize total duration
        self.freq = 0.0
        self.last_out = 0.0  # Initialize last output value
        self.Lag = Lag(world_ptr)  # Initialize Lag filter with the MMMWorld instance

    fn __repr__(self) -> String:
        return String("Env")

    fn reset_vals(mut self, times: List[Float64]):
        """Reset internal values."""
        # this should only happen when the times list is empty
        while self.times.__len__() < (times.__len__() + 1):
            self.times.insert(0, 0.0)  # Ensure times list has the same length as the input times
        for i in range(times.__len__()):
            self.times[i+1] = self.times[i] + times[i]  # Copy values from input times

        self.dur = self.times[-1]  # Set total duration to the last value in times
        if self.dur > 0.0:
            self.freq = 1.0 / self.dur
        else:
            self.freq = 0.0

    # fn next(mut self, mut buffer: Buffer, phase: Float64, interp: Int64 = 0) -> Float64:
    #     return buffer.next(0, phase, interp)  

    fn next(mut self, ref params: EnvParams, trig: Bool = True) -> Float64:
        """Generate the next envelope sample."""
        return self.next(params.values, params.times, params.curves, params.loop, trig, params.time_warp)

    fn next(mut self: Env, ref values: List[Float64], ref times: List[Float64] = List[Float64](1,1), ref curves: List[Float64] = List[Float64](1), loop: Bool = False, trig: Bool = True, time_warp: Float64 = 1.0) -> Float64:
        """Generate the next envelope sample."""

        if not self.is_active:
            if self.rising_bool_detector.next(trig):
                self.sweep.phase = 0.0  # Reset phase on trigger
                self.is_active = True  # Start the envelope
                self.reset_vals(times)
            else:
                return values[0]

        var phase = self.sweep.next(self.freq * time_warp, trig)

        if loop and phase >= 1.0:  # Check if the envelope has completed
            self.sweep.phase = 0.0  # Reset phase for looping
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

        # # Interpolate between the current and next segment
        var norm_seg = (phase - self.times[segment % len(self.times)]) / (self.times[(segment + 1) % len(self.times)] - self.times[segment % len(self.times)])  # Normalized time within the segment

        norm_seg = norm_seg ** abs(curves[segment % len(curves)])  # Apply curve to normalized segment
        
        self.last_out = lerp(values[segment], values[segment + 1], norm_seg)  # Update last output value

        return self.Lag.next(self.last_out, 0.001)

fn min_env[N: Int = 1](ramp: SIMD[DType.float64, N] = 0.01, dur: SIMD[DType.float64, N] = 0.1, rise: SIMD[DType.float64, N] = 0.001) -> SIMD[DType.float64, N]:
        """
        Create a simple envelope with specified ramp and duration. The rise and fall will be of length 'rise'.

        Args:
            ramp: (SIMD[DType.float64, N]): Current ramp position (0 to 1).
            dur: (SIMD[DType.float64, N]): Total duration of the envelope.
            rise: (SIMD[DType.float64, N]): Duration of the rise and fall segments.

        Returns:
            SIMD[DType.float64, N]: Envelope value at the current ramp position.
        """

    rise2 = rise
    out = SIMD[DType.float64, N](1.0)
    @parameter
    for i in range(N):
        if rise2[i] > dur[i]/2.0:
            rise2[i] = dur[i]/2.0
        if ramp[i] < rise2[i]/dur[i]:
            out[i] = ramp[i]*(dur[i]/rise2[i])
        elif ramp[i] > 1.0 - rise2[i]/dur[i]:
            out[i] = (1.0-ramp[i])*(dur[i]/rise2[i])
    
    return out