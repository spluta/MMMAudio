from math import sin, floor
from random import random_float64
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from .OscBuffers import OscBuffers
from .Buffer import Buffer
from .Filters import *
from .Oversampling import Oversampling
from mmm_utils.RisingBoolDetector import RisingBoolDetector

struct Phasor[N: Int = 1, os_index: Int = 0](Representable, Movable, Copyable):
    var phase: SIMD[DType.float64, N]
    var freq_mul: Float64
    var rising_bool_detector: RisingBoolDetector[N]  # Track the last reset state
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phase = SIMD[DType.float64, N](0.0)
        self.freq_mul = self.world_ptr[0].os_multiplier[os_index] / self.world_ptr[0].sample_rate
        self.rising_bool_detector = RisingBoolDetector[N]()

    fn __repr__(self) -> String:
        return String("Phasor")

    fn increment_phase(mut self: Phasor, freq: SIMD[DType.float64, self.N]):
        # freq2 = clip(freq, -self.world_ptr[0].sample_rate, self.world_ptr[0].sample_rate) 
        self.phase += (freq * self.freq_mul)
        # wouldn't this be redundant?
        # for i in range(self.N):
        #     if self.phase[i] > 1.0:
        #         self.phase[i] = self.phase[i] - floor(self.phase[i])
        self.phase = self.phase - floor(self.phase)  # Wrap phase to [0.0, 1.0]

    # could change this to get trigs for each oscillator
    @always_inline
    fn next(mut self: Phasor, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: SIMD[DType.bool, self.N] = False) -> SIMD[DType.float64, self.N]:
        # Reset phase if trig has changed from 0 to positive value

        self.increment_phase(freq)

        var resets = self.rising_bool_detector.next(trig)

        @parameter
        for i in range(self.N):
            if resets[i]:
                self.phase[i] = 0.0

        return (self.phase + phase_offset) % 1.0

struct Osc[N: Int = 1, interp: Int = 0, os_index: Int = 0](Representable, Movable, Copyable):
    """
    A wavetable oscillator capable of all standard waveforms. using linear, quadratic, or sinc interpolation and can also be set to use oversampling. 
    
    While any combination is posible, best practice is with sinc interpolation, use an oversampling index of 0 (no oversampling), 1 (2x). with linear or quadratic interpolation, use an oversampling index of 0 (no oversampling), 1 (2x), 2 (4x), 3 (8x), or 4 (16x).

    Parameters:

        N: Number of channels (default is 1).

        interp: Interpolation method (0 = linear, 1 = cubic, 2 = sinc; default is 0).
        
        os_index: Oversampling index (0 = no oversampling, 1 = 2x, 2 = 4x, etc.; default is 0).

        world_ptr: Pointer to the MMMWorld instance.

    """

    var phasor: Phasor[N, os_index]  # Instance of the Phasor
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var oversampling: Oversampling[N, 2**os_index]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phasor = Phasor[self.N, os_index](world_ptr)
        self.oversampling = Oversampling[self.N, 2**os_index](world_ptr)

    fn __repr__(self) -> String:
        return String(
            "Osc"
        )

    @always_inline
    fn next(mut self: Osc, freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), trig: Bool = False, osc_type: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](0)) -> SIMD[DType.float64, self.N]:
        """
        Generate the next oscillator sample on a single waveform type. All inputs are SIMD types except trig, which is a scalar. This means that an oscillator can have N different instances, each with its own frequency, phase offset, and waveform type, but they will all share the same trigger signal.
        
        Args:
            freq: Frequency of the oscillator in Hz (default is 100.0).

            phase_offset: Phase offset in the range [0.0, 1.0] (default is 0.0).

            trig: Trigger signal to reset the phase (default is 0.0).

            osc_type: Type of waveform (0 = Sine, 1 = Saw, 2 = Square, 3 = Triangle, 4 = BandLimited Triangle, 5 = BandLimited Saw, 6 = BandLimited Square; 
            default is 0).
        """
        var trig_mask = SIMD[DType.bool, self.N](fill=trig)

        @parameter
        if os_index == 0:
            var last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
            var phase = self.phasor.next(freq, phase_offset, trig_mask)
            @parameter
            if interp == 2:# sinc interpolation
                sample = SIMD[DType.float64, self.N](0.0)
                @parameter
                for j in range(self.N):
                    sample[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type[j])
                return sample
            else: # linear or cubic interpolation
                sample = SIMD[DType.float64, self.N](0.0)
                @parameter
                for j in range(self.N):
                    sample[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type[j])
                return sample
        else:
            alias times_os_int = 2**os_index

            @parameter
            for i in range(times_os_int):
                var last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
                var phase = self.phasor.next(freq, phase_offset, trig_mask)

                @parameter
                if interp == 2:# sinc interpolation
                    # if oversampling, add each sample to the buffer
                    sample = SIMD[DType.float64, self.N](0.0)
                    @parameter
                    for j in range(self.N):
                        sample[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type[j])
                    self.oversampling.add_sample(sample)  # Get the next sample from the Oscillator buffer using sinc interpolation
                else: # linear or cubic interpolation
                    sample = SIMD[DType.float64, self.N](0.0)
                    @parameter
                    for j in range(self.N):
                        sample[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type[j])
                    self.oversampling.add_sample(sample)  # Get the nextsample from the Oscillator buffer
            
            return self.oversampling.get_sample()

    # self.osc1.next2(freq1, 0.0, 0.0, [0,4,5,6], osc_frac1, 2, 4)
    # next2 interpolates between N different buffers 
    @always_inline
    fn next_interp(mut self: Osc, freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), trig: Bool = False, osc_types: List[Int64] = [0,4,5,6], osc_frac: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)) -> SIMD[DType.float64, self.N]:
        """
        Variable Wavetable Oscillator: Generate the next oscillator sample on a variable waveform where the output is interpolated between different waveform types. All inputs are SIMD types except trig and osc_types, which are scalar. This means that an oscillator can have N different instances, each with its own frequency, phase offset, and waveform type, but they will all share the same trigger signal and the same list of waveform types to interpolate between.
        
        Args:
            freq: Frequency of the oscillator in Hz (default is 100.0).

            phase_offset: Phase offset in the range [0.0, 1.0] (default is 0.0).

            trig: Trigger signal to reset the phase (default is 0.0).

            osc_types: List of waveform types to interpolate between (default is [0,4,5,6] - sine, triangle, saw, square).

            trig: Trigger signal to reset the phase (default is 0.0). All waveforms will reset together.

            osc_frac: Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first waveform in the osc_types list, 1.0 corresponds to the last waveform in the osc_types list, and values in between interpolate linearly between all waveforms in the list. 

        """
        var trig_mask = SIMD[DType.bool, self.N](trig)

        var osc_frac2 = Float64(len(osc_types)-1) * osc_frac

        var osc_type0: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](osc_frac2)
        var osc_type1 = SIMD[DType.int64, self.N](osc_type0 + 1)
        osc_type0 = clip(osc_type0, 0, len(osc_types)-1)
        osc_type1 = clip(osc_type1, 0, len(osc_types)-1)
        @parameter
        for i in range(self.N):
            osc_type0[i] = osc_types[osc_type0[i]]
            osc_type1[i] = osc_types[osc_type1[i]]

        osc_frac2 = osc_frac2 - floor(osc_frac2)

        var sample0 = SIMD[DType.float64, self.N](0.0)
        var sample1 = SIMD[DType.float64, self.N](0.0)

        @parameter
        if os_index == 0:
            var last_phase = self.phasor.phase
            var phase = self.phasor.next(freq, phase_offset, trig_mask)
            @parameter
            for j in range(self.N):
                @parameter
                if interp == 2:
                    sample0[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type0[j])
                    sample1[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type1[j])
                else:
                    sample0[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type0[j])
                    sample1[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type1[j])
            return lerp(sample0, sample1, osc_frac2)
        else:
            alias times_os_int = 2**os_index
            @parameter
            for i in range(times_os_int):
                var last_phase = self.phasor.phase
                var phase = self.phasor.next(freq, phase_offset, trig_mask)
                @parameter
                for j in range(self.N):
                    @parameter
                    if interp == 2:
                        sample0[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type0[j])
                        sample1[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type1[j])
                    else:
                        sample0[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type0[j])
                        sample1[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type1[j])
                self.oversampling.add_sample(lerp(sample0, sample1, osc_frac2))
            return self.oversampling.get_sample()

    # I don't think this makes sense
    # for any buffer that is not an OscBuffer
    # fn next(mut self: Osc, mut buffer: Buffer, freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), trig: Bool = False, interp: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](0)) -> SIMD[DType.float64, self.N]:
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

struct SinOsc[N: Int = 1, os_index: Int = 0] (Representable, Movable, Copyable):
    """A sine wave oscillator."""

    var osc: Osc[N, os_index]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc[self.N, os_index](world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("SinOsc")

    # with SIMD, sin operation is more efficient for 

    @always_inline
    fn next(mut self: SinOsc, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Bool = False, interp: Int64 = 0) -> SIMD[DType.float64, self.N]:
        return self.osc.next(freq, phase_offset, trig, 0)

struct LFSaw[N: Int = 1, os_index: Int = 0] (Representable, Movable, Copyable):
    """A low-frequency sawtooth oscillator."""

    var phasor: Phasor[N, os_index]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor[self.N, os_index](world_ptr)  # Initialize the Phasor with the world instance

    fn __repr__(self) -> String:
        return String("LFSaw")

    @always_inline
    fn next(mut self: LFSaw, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Bool = False, interp: Int64 = 0) -> SIMD[DType.float64, self.N]:
        # return self.osc.next(freq, phase_offset, trig, 2, interp, os_index)
        var trig_mask = SIMD[DType.bool, self.N](trig)
        return (self.phasor.next(freq, phase_offset, trig_mask) * 2.0) - 1.0

struct LFSquare[N: Int = 1, os_index: Int = 0] (Representable, Movable, Copyable):
    """A low-frequency square wave oscillator."""

    var phasor: Phasor[N, os_index]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor[self.N, os_index](world_ptr)  # Initialize the Phasor with the world instance

    fn __repr__(self) -> String:
        return String("LFSquare")

    @always_inline
    fn next(mut self: LFSquare, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Bool = False, interp: Int64 = 0) -> SIMD[DType.float64, self.N]:
        var trig_mask = SIMD[DType.bool, self.N](trig)
        return -1.0 if self.phasor.next(freq, phase_offset, trig_mask) < 0.5 else 1.0

struct LFTri[N: Int = 1, os_index: Int = 0] (Representable, Movable, Copyable):
    """A low-frequency triangle wave oscillator."""

    var phasor: Phasor[N, os_index]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor[self.N, os_index](world_ptr)  # Initialize the Phasor with the world instance

    fn __repr__(self) -> String:
        return String("LFTri")

    @always_inline
    fn next(mut self: LFTri, freq: SIMD[DType.float64, self.N] = 100.0, phase_offset: SIMD[DType.float64, self.N] = 0.0, trig: Bool = False, interp: Int64 = 0) -> SIMD[DType.float64, self.N]:
        var trig_mask = SIMD[DType.bool, self.N](trig)
        return (abs((self.phasor.next(freq, phase_offset-0.25, trig_mask) * 4.0) - 2.0) - 1.0)

struct Impulse[N: Int = 1] (Representable, Movable, Copyable):
    """An oscillator that generates an impulse signal.
    Arguments:
        world_ptr: Pointer to the MMMWorld instance.
    """
    var phasor: Phasor[N]
    var last_phase: SIMD[DType.float64, N]
    var last_trig: SIMD[DType.bool, N]
    var rising_bool_detector: RisingBoolDetector[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor[self.N](world_ptr)
        self.last_phase = SIMD[DType.float64, self.N](0.0)
        self.last_trig = SIMD[DType.bool, self.N](False)
        self.rising_bool_detector = RisingBoolDetector[self.N]()

    fn __repr__(self) -> String:
        return String("Impulse")

    @always_inline
    fn next(mut self: Impulse, freq: SIMD[DType.float64, self.N] = 100.0, trig: SIMD[DType.bool, self.N] = False) -> SIMD[DType.bool, self.N]:
        """Generate the next impulse sample."""
        phase = self.phasor.next(freq, 0.0, trig)  # Update the phase
        out: SIMD[DType.bool, self.N] = False

        for i in range(self.N):
            if (freq[i] > 0.0 and phase[i] < self.last_phase[i]) or (freq[i] < 0.0 and phase[i] > self.last_phase[i]) or (trig[i] and not self.last_trig[i]):  # Check for an impulse (crossing the 0.5 threshold)
                out[i] = True

        self.last_phase = phase
        self.last_trig = trig

        return out

    fn get_phase(mut self: Impulse) -> SIMD[DType.float64, self.N]:
        return self.phasor.phase

struct Dust[N: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency dust noise oscillator."""
    var impulse: Impulse[N]
    var freq: SIMD[DType.float64, N]
    var rising_bool_detector: RisingBoolDetector[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.impulse = Impulse[N](world_ptr)
        self.freq = SIMD[DType.float64, N](1.0)
        self.rising_bool_detector = RisingBoolDetector[N]()

    fn __repr__(self) -> String:
        return String("Dust")

    @always_inline
    fn next(mut self: Dust, freq: SIMD[DType.float64, self.N] = 100.0, trig: Bool = True) -> SIMD[DType.float64, self.N]:
        """Generate the next dust noise sample."""
        if self.rising_bool_detector.next(trig):
            self.freq = random_exp_float64(freq*0.25, freq*4.0)  # Update frequency if trig is greater than 0.0
            self.impulse.phasor.phase = 0.0  # Reset phase
            return random_float64(-1.0, 1.0)  # Return a random value between -1 and 1

        var tick = self.impulse.next(self.freq)  # Update the phase

        var out = SIMD[DType.float64, self.N](0.0)

        for i in range(self.N):
            if tick[i] == 1.0:  # If an impulse is detected
                self.freq[i] = random_exp_float64(freq[i]*0.25, freq[i]*4.0)
                out[i] = random_float64(-1.0, 1.0)  # Return a random value between -1 and 1
        return out

    @always_inline
    fn next_range(mut self: Dust, low: SIMD[DType.float64, self.N] = 100.0, high: SIMD[DType.float64, self.N] = 2000.0, trig: Bool = True) -> SIMD[DType.float64, self.N]:
        """Generate the next dust noise sample."""
        if self.rising_bool_detector.next(trig):
            self.freq = random_exp_float64(low, high)  # Update frequency if trig is greater than 0.0
            self.impulse.phasor.phase = 0.0  # Reset phase
            return random_float64(-1.0, 1.0)  # Return a random value between -1 and 1

        var tick = self.impulse.next(self.freq)  # Update the phase

        var out = SIMD[DType.float64, self.N](0.0)

        for i in range(self.N):
            if tick[i] == 1.0:  # If an impulse is detected
                self.freq[i] = random_exp_float64(low[i], high[i])
                out[i] = random_float64(-1.0, 1.0)  # Return a random value between -1 and 1
        return out

    fn get_phase(mut self: Dust) -> SIMD[DType.float64, self.N]:
        return self.impulse.last_phase

struct LFNoise[N: Int = 1, interp: Int = 0](Representable, Movable, Copyable):
    """Low-frequency noise oscillator."""
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var impulse: Impulse[N]

    # Cubic inerpolation only needs 4 points, but it needs to know the true previous point so the history
    # needs an extra point: the 4 for interpolation, plus the point that is just changed
    var history: List[SIMD[DType.float64, N]]# used for interpolation

    # history_index: the index of the history list that the impulse's phase is moving *away* from
    # phase is moving *towards* history_index + 1
    var history_index: List[Int8]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.history_index = [0 for _ in range(self.N)]
        self.impulse = Impulse[N](world_ptr)
        self.history = [SIMD[DType.float64, self.N](0.0) for _ in range(5)]
        for i in range(self.N):
            for j in range(len(self.history)):
                self.history[j][i] = random_float64(-1.0, 1.0)
        # Initialize history with random values

    fn __repr__(self) -> String:
        return String("LFNoise1")

    @always_inline
    fn next(mut self: LFNoise, freq: SIMD[DType.float64, self.N] = 100.0) -> SIMD[DType.float64, self.N]:
        """Generate the next low-frequency noise sample."""
        var tick = self.impulse.next(freq)  # Update the phase

        @parameter
        for i in range(self.N):
            if tick[i] == 1.0:  # If an impulse is detected
                # advance the history index
                self.history_index[i] = (self.history_index[i] + 1) % len(self.history)

            # so don't change that one, cubic interp needs to know that, so we'll change 
            # history_index - 2 (but, again, computed differently to avoid negative indices) so
            # the next time we wrap around to that part of the history list it will be a new random value
            self.history[(self.history_index[i] + (len(self.history) - 2)) % len(self.history)][i] = random_float64(-1.0, 1.0)

        @parameter
        if interp == 0:
            p0 = SIMD[DType.float64, self.N](0.0)
            @parameter
            for i in range(self.N):
                # return self.history[self.history_index + 1 % len(self.history)]
                p0[i] = self.history[(self.history_index[i] + 1) % len(self.history)][i]
            return p0
        elif interp == 1:
            # Linear interpolation between last and next value
            p0 = SIMD[DType.float64, self.N](0.0)
            p1 = SIMD[DType.float64, self.N](0.0)
            @parameter
            for i in range(self.N):
                p0[i] = self.history[self.history_index[i]][i]
                p1[i] = self.history[(self.history_index[i] + 1) % len(self.history)][i]
            return lerp(p0, p1, self.impulse.phasor.phase)
        else:
            p0 = SIMD[DType.float64, self.N](0.0)
            p1 = SIMD[DType.float64, self.N](0.0)
            p2 = SIMD[DType.float64, self.N](0.0)
            p3 = SIMD[DType.float64, self.N](0.0)
            @parameter
            for i in range(self.N):
                p0[i] = self.history[(self.history_index[i] + (len(self.history) - 1)) % len(self.history)][i]
                p1[i] = self.history[self.history_index[i]][i]
                p2[i] = self.history[(self.history_index[i] + 1) % len(self.history)][i]
                p3[i] = self.history[(self.history_index[i] + 2) % len(self.history)][i]
            # Cubic interpolation
            return cubic_interp(p0, p1, p2, p3, self.impulse.phasor.phase)

struct Sweep[N: Int = 1, os_index: Int = 0](Representable, Movable, Copyable):
    var phase: SIMD[DType.float64, N]
    var freq_mul: Float64
    var rising_bool_detector: RisingBoolDetector[N]  # Track the last reset state
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.phase = SIMD[DType.float64, N](0.0)
        self.freq_mul = self.world_ptr[0].os_multiplier[os_index] / self.world_ptr[0].sample_rate
        self.rising_bool_detector = RisingBoolDetector[N]()

    fn __repr__(self) -> String:
        return String("Phasor")

    # could change this to get trigs for each oscillator
    @always_inline
    fn next(mut self, freq: SIMD[DType.float64, self.N] = 100.0, trig: SIMD[DType.bool, self.N] = False) -> SIMD[DType.float64, self.N]:
        # Reset phase if trig has changed from 0 to positive value

        self.phase += (freq * self.freq_mul)

        var resets = self.rising_bool_detector.next(trig)

        @parameter
        for i in range(self.N):
            if resets[i]:
                self.phase[i] = 0.0

        return self.phase


# struct Sweep(Representable, Movable, Copyable):
#     var phase: Float64
#     var freq_mul: Float64
#     var last_trig: Float64 # Track the last reset state

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         self.phase = 0.0
#         self.freq_mul = 1.0 / world_ptr[0].sample_rate  # self.world_ptr[0].sample_rate is the sample rate of the audio system
#         self.last_trig = 0.0  # Initialize last reset state

#     fn __repr__(self) -> String:
#         return String("Sweep")

#     fn increment_phase(mut self: Sweep, freq: Float64):
#         self.phase += (freq * self.freq_mul)

#     @always_inline
#     fn next(mut self: Sweep, freq: Float64 = 100.0, trig: Bool = False) -> Float64:
#         # Reset phase if reset signal has changed from 0 to positive value
#         if trig > 0.0 and self.last_trig <= 0.0:
#             self.phase = 0.0
#         else:
#             self.increment_phase(freq)
#         self.last_trig = trig
#         return self.phase

