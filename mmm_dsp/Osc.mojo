from math import sin, floor
from random import random_float64
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from .OscBuffers import OscBuffers
from .Buffer import Buffer
from .Filters import *

struct Phasor(Representable, Movable, Copyable):
    var phase: Float64
    var freq_mul: Float64
    var last_trig: Float64 # Track the last reset state
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phase = 0.0
        self.freq_mul = 1.0 / self.world_ptr[0].sample_rate  # self.world_ptr[0].sample_rate is the sample rate of the audio system
        self.last_trig = 0.0  # Initialize last reset state

    fn __repr__(self) -> String:
        return String("Phasor")

    fn increment_phase(mut self: Phasor, freq: Float64, os_index: Int64 = 0):

        self.phase += (freq * self.freq_mul * self.world_ptr[0].os_multiplier[os_index])
        if self.phase >= 1.0:
            self.phase -= 1.0
        elif self.phase < 0.0:
            self.phase += 1.0  # Ensure phase is always positive

    # not so sure about this pm
    fn next(mut self: Phasor, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, os_index: Int64 = 0) -> Float64:
        # Reset phase if reset signal has changed from 0 to positive value
        if trig > 0.0 and self.last_trig <= 0.0:
            self.phase = 0.0
        else:
            self.increment_phase(freq, os_index)
        self.last_trig = trig
        return wrap(self.phase + phase_offset, 0.0, 1.0)  # Wrap phase to [0, 1) range

struct Osc(Representable, Movable, Copyable):
    var phasor: Phasor
    var os_array: InlineArray[Float64, 16]  # Array for oscillator samples
    var os_filter: lpf_LR4
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phasor = Phasor(world_ptr)
        self.os_array = InlineArray[Float64, 16](fill=0.0)  # Initialize the oscillator sample array
        self.os_filter = lpf_LR4(world_ptr)  # Initialize the oscillator filter

    fn __repr__(self) -> String:
        return String(
            "Osc"
        )

    fn next(mut self: Osc, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, osc_type: Int64 = 0, interp: Int64 = 1, os_index: Int64 = 0) -> Float64:
        var sample: Float64 = 0.0  # Initialize sample

        for i in range(2 ** os_index):
            if i >= len(self.os_array):
                break  # Prevent index out of bounds
            if interp == 2:
                var last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
                var phase = self.phasor.next(freq, phase_offset, trig, os_index)  # Update the phase

                self.os_array[i] = self.world_ptr[0].osc_buffers.next_sinc(phase, last_phase, osc_type)  # Get the next sample from the Oscillator buffer using sinc interpolation
            else:
                var phase = self.phasor.next(freq, phase_offset, trig, os_index)  # Update the phase
                self.os_array[i] = self.world_ptr[0].osc_buffers.next(phase, osc_type, interp)  # Get the next sample from the Oscillator buffer

        if os_index == 0:
            sample = self.os_array[0]  # If no oversampling, take the first sample directly
        else:
            var fc = 0.98 * self.os_filter.sample_rate * 0.5 / (Float64(2 ** os_index))  # Calculate the cutoff frequency for the filter
            for i in range(2 ** os_index):
                sample = self.os_filter.next(self.os_array[i], fc)  # Sum the oscillator samples

        return sample

    # next2 interpolates between 2 different buffers 
    fn next2(mut self: Osc, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, osc_types: List[Int64] = [0,4,5,6], osc_frac: Float64 = 0.0, interp: Int64 = 0, os_index: Int64 = 0) -> Float64:

        var sample: Float64 = 0.0  # Initialize sample
        var osc_type0 = Int64(Float64(len(osc_types)) * osc_frac)
        var osc_type1 = (osc_type0 + 1) % len(osc_types)
        osc_type0 = osc_types[osc_type0]
        osc_type1 = osc_types[osc_type1]
        var osc_frac2 = Float64(len(osc_types)) * osc_frac
        osc_frac2 = osc_frac2 - floor(osc_frac2)

        # print(osc_frac, osc_frac2, osc_type0, osc_type1)

        for i in range(2 ** os_index):
            if i >= len(self.os_array):
                break  

            if interp == 2:
                var last_phase = self.phasor.phase 
                var phase = self.phasor.next(freq, phase_offset, trig, os_index) 
                self.os_array[i] = self.world_ptr[0].osc_buffers.next_sinc(phase, last_phase, osc_type0) * (1.0 - osc_frac2) + \
                                   self.world_ptr[0].osc_buffers.next_sinc(phase, last_phase, osc_type1) * osc_frac2  # Get the next sample from the Oscillator buffer using sinc interpolation
            else:
                var phase = self.phasor.next(freq, phase_offset, trig, os_index)  # Update the phase
                self.os_array[i] = self.world_ptr[0].osc_buffers.next(phase, osc_type0, interp) * (1.0 - osc_frac2) + \
                                   self.world_ptr[0].osc_buffers.next(phase, osc_type1, interp) * osc_frac2

        if os_index == 0:
            sample = self.os_array[0]  # If no oversampling, take the first sample directly
        else:
            # postln("Oversampling index:", os_index, "with", 2 ** os_index, "samples")
            var fc = 0.98 * self.os_filter.sample_rate * 0.5 / (Float64(2 ** os_index))  # Calculate the cutoff frequency for the filter
            for i in range(2 ** os_index):
                sample = self.os_filter.next(self.os_array[i], fc)  # Sum the oscillator samples

        return sample


    # for any buffer that is not an OscBuffer
    fn next(mut self: Osc, mut buffer: Buffer, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, interp: Int64 = 0) -> Float64:
        var sample: Float64 = 0.0  # Initialize sample

        if interp == 2:
            var last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
            var phase = self.phasor.next(freq, phase_offset)  # Update the phase
            sample = buffer.next_sinc(0, phase, last_phase)  # Get the next sample from the Oscillator buffer using sinc interpolation
        else:
            var phase = self.phasor.next(freq, phase_offset)  # Update the phase
            sample = buffer.next(0, phase, interp)  # Get the next sample from the Oscillator buffer
        return sample

    # fn next(mut self: Osc, mut buffer: Buffer, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, osc_types: List[Int64] = [0,4,5,6], osc_frac: Float64 = 0.0, interp: Int64 = 0, os_index: Int64 = 0) -> Float64:


struct SinOsc (Representable, Movable, Copyable):
    """A sine wave oscillator."""

    var osc: Osc  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc(world_ptr)  # Initialize the Oscillator with the world instance
    
    fn __repr__(self) -> String:
        return String("SinOsc")

    fn next(mut self: SinOsc, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int64 = 0) -> Float64:
        return self.osc.next(freq, phase_offset, trig, 0, interp, os_index)

struct LFSaw (Representable, Movable, Copyable):
    """A low-frequency sawtooth oscillator."""

    var osc: Osc  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc(world_ptr)  # Initialize the Oscillator with the world instance
    
    fn __repr__(self) -> String:
        return String("LFSaw")

    fn next(mut self: LFSaw, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int64 = 0) -> Float64:
        return self.osc.next(freq, phase_offset, trig, 2, interp, os_index)

struct LFSquare (Representable, Movable, Copyable):
    """A low-frequency square wave oscillator."""

    var osc: Osc  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc(world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("LFSquare")

    fn next(mut self: LFSquare, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int64 = 0) -> Float64:
        return self.osc.next(freq, phase_offset, trig, 1, interp, os_index)

struct LFTri (Representable, Movable, Copyable):
    """A low-frequency triangle wave oscillator."""

    var osc: Osc  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc(world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("LFTri")

    fn next(mut self: LFTri, freq: Float64 = 100.0, phase_offset: Float64 = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int64 = 0) -> Float64:
        return self.osc.next(freq, phase_offset, trig, 3, interp, os_index)

struct Impulse(Representable, Movable, Copyable):
    """An oscillator that generates an impulse signal.
    Arguments:
        world_ptr: Pointer to the MMMWorld instance.
    """
    var phasor: Phasor
    var last_phase: Float64  
    var last_trig: Float64  

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor(world_ptr)
        self.last_phase = 0.0
        self.last_trig = 0.0

    fn __repr__(self) -> String:
        return String("Impulse")

    fn next(mut self: Impulse, freq: Float64 = 100.0, trig: Float64 = 0.0) -> Float64:
        """Generate the next impulse sample."""
        var phase = self.phasor.next(abs(freq), 0.0, trig)  # Update the phase

        if trig > 0.0 and self.last_trig <= 0.0:
            self.last_phase = phase  # Update last phase if trig is greater than 0.0
            self.last_trig = trig  # Update last trigger state
            return 1.0  # Return impulse value

        if abs(phase - self.last_phase) >= 0.5:  # Check for an impulse (crossing the 0.5 threshold)
            self.last_phase = phase 
            self.last_trig = trig 
            return 1.0  # Return impulse value
        else:
            self.last_phase = phase 
            self.last_trig = trig 
            return 0.0  # Return zero if no impulse

struct LFNoise(Representable, Movable, Copyable):
    """Low-frequency noise oscillator."""
    var impulse: Impulse
    var last_value: Float64  # Track the last value to generate noise
    var next_value: Float64  # Track the next value to generate noise

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.impulse = Impulse(world_ptr)
        self.last_value = 0.0  # Initialize last value
        self.next_value = random_float64(-1.0, 1.0)

    fn __repr__(self) -> String:
        return String("LFNoise1")

    fn next(mut self: LFNoise, freq: Float64 = 100.0, interp: Int64 = 0) -> Float64:
        """Generate the next low-frequency noise sample."""
        var tick = self.impulse.next(freq)  # Update the phase
        var sample: Float64
        if interp == 0:
            sample = self.next_value  # Return the next value directly if no interpolation
        elif interp == 1:
            # Linear interpolation between last and next value
            sample = self.impulse.phasor.phase * (self.next_value - self.last_value) + self.last_value
        else:
            sample = cubic_interpolation(self.last_value, self.next_value, self.impulse.phasor.phase)  # Cubic interpolation

        if tick == 1.0:  # If an impulse is detected
            self.last_value = self.next_value  # Update last value
            self.next_value = random_float64(-1.0, 1.0)  # Generate a new random value

        return sample

struct Sweep(Representable, Movable, Copyable):
    var phase: Float64
    var freq_mul: Float64
    var last_trig: Float64 # Track the last reset state

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phase = 0.0
        self.freq_mul = 1.0 / world_ptr[0].sample_rate  # self.world_ptr[0].sample_rate is the sample rate of the audio system
        self.last_trig = 0.0  # Initialize last reset state

    fn __repr__(self) -> String:
        return String("Sweep")

    fn increment_phase(mut self: Sweep, freq: Float64):
        self.phase += (freq * self.freq_mul)

    fn next(mut self: Sweep, freq: Float64 = 100.0, trig: Float64 = 0.0) -> Float64:
        # Reset phase if reset signal has changed from 0 to positive value
        if trig > 0.0 and self.last_trig <= 0.0:
            self.phase = 0.0
        else:
            self.increment_phase(freq)
        self.last_trig = trig
        return self.phase

