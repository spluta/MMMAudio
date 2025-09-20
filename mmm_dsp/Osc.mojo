from math import sin, floor
from random import random_float64
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from .OscBuffers import OscBuffers
from .Buffer import Buffer
from .Filters import *
from .Oversampling import Oversampling

struct Phasor[N: Int = 1](Representable, Movable, Copyable):
    var phase: SIMD[DType.float64, N]
    var freq_mul: Float64
    var last_trig: Float64 # Track the last reset state
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phase = SIMD[DType.float64, self.N](0.0)
        self.freq_mul = 1.0 / self.world_ptr[0].sample_rate  # self.world_ptr[0].sample_rate is the sample rate of the audio system
        self.last_trig = 0.0  # Initialize last reset state

    fn __repr__(self) -> String:
        return String("Phasor")

    fn increment_phase(mut self: Phasor, freq: SIMD[DType.float64, self.N], os_index: Int = 0):
        freq2 = clip(freq, -self.world_ptr[0].sample_rate, self.world_ptr[0].sample_rate) 
        self.phase += (freq2 * self.freq_mul * self.world_ptr[0].os_multiplier[os_index])
        # ensure that phase is always positive
        for i in range(self.N):
            if self.phase[i] > 1.0:
                self.phase[i] = self.phase[i] - floor(self.phase[i])
        self.phase = self.phase % 1.0

    # could change this to get trigs for each oscillator
    fn next(mut self: Phasor, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Float64 = 0.0, os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        # Reset phase if trig has changed from 0 to positive value

        if trig > 0.0 and self.last_trig <= 0.0:
            self.phase = 0.0
        else:
            self.increment_phase(freq, os_index)
        self.last_trig = trig

        return (self.phase + phase_offset) % 1.0

# struct Osc[N: Int = 1](Representable, Movable, Copyable):
#     """Oscillator structure for generating waveforms.

#     Osc is a swiss-army knive oscillator. It can utilize the 7 OscBuffers that are built into MMM (Sine, Triangle, Sawtooth, Square, Bandlimited Tri, Saw, Square) and can also load any waveform that can function as a wavetable. It can use linear interpolation, quadratic interpolation, or sinc interpolation. It also has oversampling up to 16x. Finally, it can interpolate between waveforms, creating a variable wavetable oscillator.

#     """
#     var oscs: List[Osc1]

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         self.oscs = List[Osc1]()
#         for _ in range(N):
#             self.oscs.append(Osc1(world_ptr))

#     fn __repr__(self) -> String:
#         return String("Osc")

#     fn next(mut self: Osc[N], freq: SIMD[DType.float64, N] = SIMD[DType.float64, N](100.0), phase_offset: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0), trig: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0), osc_type: SIMD[DType.int64, N] = SIMD[DType.int64, N](0), interp: SIMD[DType.int64, N] = SIMD[DType.int64, N](1), os_index: Int = 0) -> SIMD[DType.float64, N]:
#         """Generate the next sample from N oscillators. \n
#         Args:
#           freq: Frequency of the oscillator in Hz.
#           phase_offset: Phase offset in the range [0.0, 1.0].
#           trig: Trigger signal to reset the phase.
#           osc_type: Type of waveform (0 = Sine, 1 = Square, 2 = Sawtooth, 3 = Triangle, 4 = Bandlimited Triangle, 5 = Bandlimited Sawtooth, 6 = Bandlimited Square).
#           interp: Interpolation method (0 = linear, 1 = cubic, 2 = sinc).
#           os_index: Oversampling index (0 = no oversampling, 1 = 2x, 2 = 4x, 3 = 8x, 4 = 16x).
        
#         """


#         var out = SIMD[DType.float64, N](0.0)
#         for i in range(N):
#             out[i] = self.oscs[i].next(freq[i], phase_offset[i], trig[i], osc_type[i], interp[i], os_index)
#         return out
    
#     fn next2(mut self: Osc[N], freq: SIMD[DType.float64, N] = SIMD[DType.float64, N](100.0), phase_offset: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0), trig: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0), osc_types: List[Int64] = [0,4,5,6], osc_frac: SIMD[DType.float64, N] = SIMD[DType.float64, N](0.0), interp: SIMD[DType.int64, N] = SIMD[DType.int64, N](1), os_index: Int = 0) -> SIMD[DType.float64, N]:
#         var out = SIMD[DType.float64, N](0.0)
#         for i in range(N):
#             out[i] = self.oscs[i].next2(freq[i], phase_offset[i], trig[i], osc_types, osc_frac[i], interp[i], os_index)
#         return out

struct Osc[N: Int = 1](Representable, Movable, Copyable):
    

    var phasor: Phasor[N]
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var oversampling: Oversampling[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phasor = Phasor[self.N](world_ptr)
        self.oversampling = Oversampling[self.N](world_ptr) 

    fn __repr__(self) -> String:
        return String(
            "Osc"
        )

    fn next(mut self: Osc, freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), trig: Float64 = 0.0, osc_type: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](0), interp: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](1), os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        # if self.oversampling.index != os_index:
        #     self.oversampling.set_os_index(os_index)
        self.oversampling.set_os_index(os_index)

        for i in range(self.oversampling.times_os_int):
            var last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
            var phase = self.phasor.next(freq, phase_offset, trig, self.oversampling.index)  # Update the phase

            if interp == 2:# sinc interpolation
                # if no oversampling, just return the value
                if self.oversampling.index == 0:
                    sample = SIMD[DType.float64, self.N](0.0)
                    for j in range(self.N):
                        sample[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type[j])  # If no oversampling, take the first sample directly
                    return sample
                else:
                    # if oversampling, add each sample to the buffer
                    sample = SIMD[DType.float64, self.N](0.0)
                    for j in range(self.N):
                        sample[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type[j])
                    self.oversampling.add_sample(sample)  # Get the next sample from the Oscillator buffer using sinc interpolation
            else: # linear or cubic interpolation
                # if no oversampling, just return the value
                if self.oversampling.index == 0:
                    sample = SIMD[DType.float64, self.N](0.0)
                    for j in range(self.N):
                        sample[j] = self.world_ptr[0].osc_buffers.read(phase[j], osc_type[j], interp[j])  # If no oversampling, take the first sample directly
                    return sample
                else:
                    sample = SIMD[DType.float64, self.N](0.0)
                    for j in range(self.N):
                        sample[j] = self.world_ptr[0].osc_buffers.read(phase[j], osc_type[j], interp[j])
                    self.oversampling.add_sample(sample)  # Get the nextsample from the Oscillator buffer

        return self.oversampling.get_sample()

    # self.osc1.next2(freq1, 0.0, 0.0, [0,4,5,6], osc_frac1, 2, 4)
    # next2 interpolates between N different buffers 
    fn next_interp(mut self: Osc, freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), trig: Float64 = 0.0, osc_types: List[Int64] = [0,4,5,6], osc_frac: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), interp: Int64 = 1, os_index: Int = 0) -> SIMD[DType.float64, self.N]:

        var osc_type0 = SIMD[DType.int64, self.N](Float64(len(osc_types)) * osc_frac)
        var osc_type1 = (osc_type0 + 1) % len(osc_types)
        osc_type0 = osc_types[osc_type0]
        osc_type1 = osc_types[osc_type1]
        var osc_frac2 = Float64(len(osc_types)) * osc_frac
        osc_frac2 = osc_frac2 - floor(osc_frac2)

        if self.oversampling.index != os_index:
            self.oversampling.set_os_index(os_index)

        for i in range(self.oversampling.times_os_int):
            if interp == 2:
                var last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
                var phase = self.phasor.next(freq, phase_offset, trig, self.oversampling.index)  # Update the phase

                # sample = self.world_ptr[0].osc_buffers.read_sinc(phase, last_phase, osc_type0) * (1.0 - osc_frac2) + \
                #                             self.world_ptr[0].osc_buffers.read_sinc(phase, last_phase, osc_type1) * osc_frac2

                sample0 = SIMD[DType.float64, self.N](0.0)
                sample1 = SIMD[DType.float64, self.N](0.0)
                for j in range(self.N):
                    sample0[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type0[j])
                    sample1[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type1[j])
                self.oversampling.add_sample(lerp(sample0, sample1, osc_frac2))
 
            else:
                var phase = self.phasor.next(freq, phase_offset, trig, self.oversampling.index)  # Update the phase
                sample0 = SIMD[DType.float64, self.N](0.0)
                sample1 = SIMD[DType.float64, self.N](0.0)
                for j in range(self.N):
                    sample0[j] = self.world_ptr[0].osc_buffers.read(phase[j], osc_type0[j], interp[j])
                    sample1[j] = self.world_ptr[0].osc_buffers.read(phase[j], osc_type1[j], interp[j])
                self.oversampling.add_sample(lerp(sample0, sample1, osc_frac2))  # Get the next sample from the Oscillator buffer

        sample = SIMD[DType.float64, self.N](0.0)

        if self.oversampling.index == 0:
            sample = self.oversampling.buffer[0]  # If no oversampling, take the first sample directly
        else:
            sample = self.oversampling.get_sample()

        return sample

    # I don't think this makes sense
    # for any buffer that is not an OscBuffer
    # fn next(mut self: Osc, mut buffer: Buffer, freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), trig: Float64 = 0.0, interp: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](0)) -> SIMD[DType.float64, self.N]:
    #     sample = SIMD[DType.float64, self.N](0.0)
    #     if interp == 2:
    #         last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
    #         phase = self.phasor.next(freq, phase_offset)  # Update the phase
    #         sample = SIMD[DType.float64, self.N](0.0)
    #         # sample = buffer.read_sinc(0, phase, last_phase)  # Get the next sample from the Oscillator buffer using sinc interpolation
    #     else:
    #         phase = self.phasor.next(freq, phase_offset)  # Update the phase
    #         sample = buffer.read(0, phase, interp) 
    #     return sample

struct SinOsc[N: Int = 1] (Representable, Movable, Copyable):
    """A sine wave oscillator."""

    var osc: Osc[N]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc[self.N](world_ptr)  # Initialize the Oscillator with the world instance
    
    fn __repr__(self) -> String:
        return String("SinOsc")

    fn next(mut self: SinOsc, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        return self.osc.next(freq, phase_offset, trig, 0, interp, os_index)

struct LFSaw[N: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency sawtooth oscillator."""

    var osc: Osc[N]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc[self.N](world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("LFSaw")

    fn next(mut self: LFSaw, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        return self.osc.next(freq, phase_offset, trig, 2, interp, os_index)

struct LFSquare[N: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency square wave oscillator."""

    var osc: Osc[N]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc[self.N](world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("LFSquare")

    fn next(mut self: LFSquare, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        return self.osc.next(freq, phase_offset, trig, 1, interp, os_index)

struct LFTri[N: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency triangle wave oscillator."""

    var osc: Osc[N]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc[self.N](world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("LFTri")

    fn next(mut self: LFTri, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Float64 = 0.0, interp: Int64 = 0, os_index: Int = 0) -> SIMD[DType.float64, self.N]:
        return self.osc.next(freq, phase_offset, trig, 3, interp, os_index)

struct Impulse[N: Int = 1] (Representable, Movable, Copyable):
    """An oscillator that generates an impulse signal.
    Arguments:
        world_ptr: Pointer to the MMMWorld instance.
    """
    var phasor: Phasor[N]
    var last_phase: SIMD[DType.float64, N]
    var last_trig: Float64  # Track the last trigger state

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor[self.N](world_ptr)
        self.last_phase = SIMD[DType.float64, self.N](0.0)
        self.last_trig = 0.0

    fn __repr__(self) -> String:
        return String("Impulse")

    fn next(mut self: Impulse, freq: SIMD[DType.float64, self.N] = 100.0, trig: Float64 = 0.0) -> SIMD[DType.float64, self.N]:
        """Generate the next impulse sample."""
        var phase = self.phasor.next(abs(freq), 0.0, trig)  # Update the phase

        if trig > 0.0 and self.last_trig <= 0.0:
            self.last_phase = phase  # Update last phase if trig is greater than 0.0
            self.last_trig = trig  # Update last trigger state
            return 1.0  # Return impulse value

        out = SIMD[DType.float64, self.N](0.0)
        for i in range(self.N):
             if phase[i] < self.last_phase[i]:  # Check for an impulse (crossing the 0.5 threshold)
                out[i] = 1.0  # Return

        self.last_phase = phase 
        self.last_trig = trig 

        return out

    fn get_phase(mut self: Impulse) -> SIMD[DType.float64, self.N]:
        return self.phasor.phase

struct Dust[N: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency dust noise oscillator."""
    var impulse: Impulse[N]
    var freq: SIMD[DType.float64, N]
    var last_trig: Float64  # Track the last reset state

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.impulse = Impulse[self.N](world_ptr)
        self.freq = SIMD[DType.float64, self.N](1.0)
        self.last_trig = 0.0

    fn __repr__(self) -> String:
        return String("Dust")

    fn next(mut self: Dust, freq: SIMD[DType.float64, self.N] = 100.0, trig: Float64 = 1.0) -> SIMD[DType.float64, self.N]:
        """Generate the next dust noise sample."""
        if trig > 0.0 and self.last_trig <= 0.0:
            self.last_trig = trig
            self.freq = random_exp_float64(freq*0.25, freq*4.0)  # Update frequency if trig is greater than 0.0
            self.impulse.phasor.phase = 0.0  # Reset phase
            return random_float64(-1.0, 1.0)  # Return a random value between -1 and 1
        self.last_trig = trig

        var tick = self.impulse.next(self.freq)  # Update the phase

        var out = SIMD[DType.float64, self.N](0.0)

        for i in range(self.N):
            if tick[i] == 1.0:  # If an impulse is detected
                self.freq[i] = random_exp_float64(freq[i]*0.25, freq[i]*4.0)
                out[i] = random_float64(-1.0, 1.0)  # Return a random value between -1 and 1
        return out

    fn next_range(mut self: Dust, low: SIMD[DType.float64, self.N] = 100.0, high: SIMD[DType.float64, self.N] = 2000.0, trig: Float64 = 1.0) -> SIMD[DType.float64, self.N]:
        """Generate the next dust noise sample."""
        if trig > 0.0 and self.last_trig <= 0.0:
            self.last_trig = trig
            self.freq = random_exp_float64(low, high)  # Update frequency if trig is greater than 0.0
            self.impulse.phasor.phase = 0.0  # Reset phase
            return random_float64(-1.0, 1.0)  # Return a random value between -1 and 1
        self.last_trig = trig

        var tick = self.impulse.next(self.freq)  # Update the phase

        var out = SIMD[DType.float64, self.N](0.0)

        for i in range(self.N):
            if tick[i] == 1.0:  # If an impulse is detected
                self.freq[i] = random_exp_float64(low[i], high[i])
                out[i] = random_float64(-1.0, 1.0)  # Return a random value between -1 and 1
        return out

    fn get_phase(mut self: Dust) -> SIMD[DType.float64, self.N]:
        return self.impulse.last_phase

struct LFNoise(Representable, Movable, Copyable):
    """Low-frequency noise oscillator."""
    var impulse: Impulse

    # Cubic inerpolation only needs 4 points, but it needs to know the true previous point so the history
    # needs an extra point: the 4 for interpolation, plus the point that is just changed
    var history: List[Float64,5] # used for interpolation

    # history_index: the index of the history list that the impulse's phase is moving *away* from
    # phase is moving *towards* history_index + 1
    var history_index: Int8

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.history_index = 0
        self.impulse = Impulse(world_ptr)
        for ref h in self.history:
            h = random_float64(-1.0, 1.0)

    fn __repr__(self) -> String:
        return String("LFNoise1")

    fn next(mut self: LFNoise, freq: Float64 = 100.0, interp: Int64 = 0) -> Float64:
        """Generate the next low-frequency noise sample."""
        var tick = self.impulse.next(freq)  # Update the phase

        if tick == 1.0:  # If an impulse is detected
            # advance the history index
            self.history_index = (self.history_index + 1) % len(self.history)
            # now, the current history_index will be used as cubic interpolation's p1,
            # history_index - 1 (but computed differently to avoid negative indices) will be p0,
            # so don't change that one, cubic interp needs to know that, so we'll change 
            # history_index - 2 (but, again, computed differently to avoid negative indices) so
            # the next time we wrap around to that part of the history list it will be a new random value
            self.history[self.history_index + (len(self.history) - 2) % len(self.history)] = random_float64(-1.0, 1.0)

        if interp == 0:
            # no interpolation (sample & hold behavior)
            return self.history[self.history_index + 1 % len(self.history)]
        elif interp == 1:
            # Linear interpolation between last and next value
            var p0 = self.history[self.history_index]
            var p1 = self.history[(self.history_index + 1) % len(self.history)]
            return lerp(p0, p1, self.impulse.phasor.phase)
        else:
            var p0: Float64 = self.history[(self.history_index + (len(self.history) - 1)) % len(self.history)]
            var p1: Float64 = self.history[self.history_index]
            var p2: Float64 = self.history[(self.history_index + 1) % len(self.history)]
            var p3: Float64 = self.history[(self.history_index + 2) % len(self.history)]
            return cubic_interp(p0,p1,p2,p3, self.impulse.phasor.phase)  # Cubic interpolation


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

