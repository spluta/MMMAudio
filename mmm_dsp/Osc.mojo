from math import sin, floor
from random import random_float64
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from .Buffer import *
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
        self.phase += (freq * self.freq_mul)
        self.phase = self.phase - floor(self.phase)  

    @always_inline
    fn next(
            mut self: Phasor, 
            freq: SIMD[DType.float64, self.N] = 100.0, 
            phase_offset: SIMD[DType.float64, self.N] = 0.0, 
            trig: SIMD[DType.bool, self.N] = False
        ) -> SIMD[DType.float64, self.N]:

        self.increment_phase(freq)
        var resets = self.rising_bool_detector.next(trig)
        # SIMD conditional reset - no loop needed!
        self.phase = resets.select(0.0, self.phase)
        
        return (self.phase + phase_offset) % 1.0

struct OscType:
    alias sine: Int64 = 0
    alias saw: Int64 = 1
    alias square: Int64 = 2
    alias triangle: Int64 = 3
    alias bandlimited_triangle: Int64 = 4
    alias bandlimited_saw: Int64 = 5
    alias bandlimited_square: Int64 = 6

struct Osc[N: Int = 1, interp: Int = 0, os_index: Int = 0](Representable, Movable, Copyable):
    """
    A wavetable oscillator capable of all standard waveforms. using linear, quadratic, or sinc interpolation and can also be set to use oversampling. 

    While any combination is posible, best practice is with sinc interpolation, use an oversampling index of 0 (no oversampling), 1 (2x). with linear or quadratic interpolation, use an oversampling index of 0 (no oversampling), 1 (2x), 2 (4x), 3 (8x), or 4 (16x).

    Params:
        N: Number of channels (default is 1).
        interp: Interpolation method (0 = linear, 1 = cubic, 2 = sinc; default is 0).
        os_index: Oversampling index (0 = no oversampling, 1 = 2x, 2 = 4x, etc.; default is 0).

    Args:
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
    fn next(
            mut self: Osc, 
            freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), 
            phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), 
            trig: Bool = False, 
            osc_type: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](0)
        ) -> SIMD[DType.float64, self.N]:
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
            if interp == Interp.sinc:
                out = SIMD[DType.float64, self.N](0.0)
                @parameter
                for j in range(self.N):
                    out[j] = self.world_ptr[0].osc_buffers.read_sinc(phase[j], last_phase[j], osc_type[j])
                return out
            else: # linear or cubic interpolation
                out = SIMD[DType.float64, self.N](0.0)
                @parameter
                for j in range(self.N):
                    out[j] = self.world_ptr[0].osc_buffers.read[interp](phase[j], osc_type[j])
                return out
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

    @always_inline
    fn next_vwt(
            mut self: Osc, 
            freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), 
            phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), 
            trig: Bool = False, 
            osc_types: List[Int64] = [0,4,5,6], 
            osc_frac: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        ) -> SIMD[DType.float64, self.N]:
        """Variable Wavetable Oscillator using built-in waveforms.
        
        Generate the next oscillator sample on a variable waveform where the output is interpolated between 
        different waveform types. All inputs are SIMD types except trig and osc_types, which are scalar. This 
        means that an oscillator can have N different instances, each with its own frequency, phase offset, 
        and waveform type, but they will all share the same trigger signal and the same list of waveform types 
        to interpolate between.
        
        Args:
            freq: Frequency of the oscillator in Hz (default is 100.0).
            phase_offset: Phase offset in the range [0.0, 1.0] (default is 0.0).
            trig: Trigger signal to reset the phase (default is 0.0).
            osc_types: List of waveform types to interpolate between (default is [0,4,5,6] - sine, triangle, saw, square).
            trig: Trigger signal to reset the phase (default is 0.0). All waveforms will reset together.
            osc_frac: Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first waveform in the osc_types list, 1.0 corresponds to the last waveform in the osc_types list, and values in between interpolate linearly between all waveforms in the list. 

        """
        var trig_mask = SIMD[DType.bool, self.N](fill=trig)

        var len_m1 = len(osc_types)-1

        var osc_frac2 = Float64(len_m1) * osc_frac

        var osc_type0: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](osc_frac2)
        var osc_type1 = SIMD[DType.int64, self.N](osc_type0 + 1)
        osc_type0 = clip(osc_type0, 0,  len_m1)
        osc_type1 = clip(osc_type1, 0, len_m1)
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
            return linear_interp(sample0, sample1, osc_frac2)
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
                self.oversampling.add_sample(linear_interp(sample0, sample1, osc_frac2))
            return self.oversampling.get_sample()
    
    @always_inline
    fn next_vwt(
            mut self: Osc, 
            ref buffer: Buffer, 
            freq: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](100.0), 
            phase_offset: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0), 
            trig: Bool = False, 
            osc_frac: SIMD[DType.float64, self.N] = SIMD[DType.float64, self.N](0.0)
        ) -> SIMD[DType.float64, self.N]:
        """Variable Wavetable Oscillator with loaded Buffer.
        
        Generate the next oscillator sample on a variable waveform where the output is interpolated between 
        different waveform types. All inputs are SIMD types except trig and osc_types, which are scalar. This 
        means that an oscillator can have N different instances, each with its own frequency, phase offset, 
        and waveform type, but they will all share the same trigger signal and the same list of waveform types 
        to interpolate between.
        
        Args:
            buffer: Reference to a Buffer containing the waveforms to interpolate between.
            freq: Frequency of the oscillator in Hz (default is 100.0).
            phase_offset: Phase offset in the range [0.0, 1.0] (default is 0.0).
            trig: Trigger signal to reset the phase (default is 0.0). All waveforms will reset together.
            osc_frac: Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first waveform in the osc_types list, 1.0 corresponds to the last waveform in the osc_types list, and values in between interpolate linearly between all waveforms in the list. 
        """
        var trig_mask = SIMD[DType.bool, self.N](fill=trig)

        var len_m1 = buffer.num_chans-1

        var chan0_fl = Float64(len_m1) * (osc_frac % 1.0)

        var chan0: SIMD[DType.int64, self.N] = SIMD[DType.int64, self.N](chan0_fl)
        var chan1 = SIMD[DType.int64, self.N](chan0 + 1)

        osc_frac2 = chan0_fl - floor(chan0_fl)

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
                    sample0[j] = buffer.read_sinc(phase[j], last_phase[j], chan0[j])
                    sample1[j] = buffer.read_sinc(phase[j], last_phase[j], chan1[j])

                else:
                    sample0[j] = buffer.read_phase[1, interp](chan0[j], phase[j])
                    sample1[j] = buffer.read_phase[1, interp](chan1[j], phase[j])
            return linear_interpsample0, sample1, osc_frac2)
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
                        sample0[j] = buffer.read_sinc(phase[j], last_phase[j], chan0[j])
                        sample1[j] = buffer.read_sinc(phase[j], last_phase[j], chan1[j])
                    else:
                        sample0[j] = buffer.read_phase[1, interp](chan0[j], phase[j])
                        sample1[j] = buffer.read_phase[1, interp](chan1[j], phase[j])
                self.oversampling.add_sample(linear_interpsample0, sample1, osc_frac2))
            return self.oversampling.get_sample()


struct SinOsc[N: Int = 1, os_index: Int = 0] (Representable, Movable, Copyable):
    """A sine wave oscillator.
    
    This is a convenience struct as internally it uses Osc and indicates `osc_type = 0`
    """

    var osc: Osc[N, os_index]  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.osc = Osc[self.N, os_index](world_ptr)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("SinOsc")

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
        var trig_mask = SIMD[DType.bool, self.N](fill=trig)
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
        var trig_mask = SIMD[DType.bool, self.N](fill=trig)
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
        var trig_mask = SIMD[DType.bool, self.N](fill=trig)
        return (abs((self.phasor.next(freq, phase_offset-0.25, trig_mask) * 4.0) - 2.0) - 1.0)

struct Impulse[N: Int = 1] (Representable, Movable, Copyable):
    """An oscillator that generates an impulse signal.
    Args:
        world_ptr: Pointer to the MMMWorld instance.
    """
    var phasor: Phasor[N]
    var last_phase: SIMD[DType.float64, N]
    var last_trig: SIMD[DType.bool, N]
    var rising_bool_detector: RisingBoolDetector[N]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.phasor = Phasor[self.N](world_ptr)
        self.last_phase = SIMD[DType.float64, self.N](0.0)
        self.last_trig = SIMD[DType.bool, self.N](fill=False)
        self.rising_bool_detector = RisingBoolDetector[self.N]()

    fn __repr__(self) -> String:
        return String("Impulse")

    # @always_inline
    # fn next(mut self: Impulse, freq: SIMD[DType.float64, self.N] = 100.0, trig: SIMD[DType.bool, self.N] = False) -> SIMD[DType.float64, self.N]:
    #     return Float64(self.next(freq, trig))

    @always_inline
    fn next(mut self: Impulse, freq: SIMD[DType.float64, self.N] = 100, trig: SIMD[DType.bool, self.N] = SIMD[DType.bool, self.N](fill=True)) -> SIMD[DType.float64, self.N]:

        return SIMD[DType.float64, self.N](self.next_bool(freq, trig).cast[DType.float64]())

    @always_inline
    fn next_bool(mut self: Impulse, freq: SIMD[DType.float64, self.N] = 100, trig: SIMD[DType.bool, self.N] = SIMD[DType.bool, self.N](fill=True)) -> SIMD[DType.bool, self.N]:
        """Generate the next impulse sample."""
        phase = self.phasor.next(freq, 0.0, trig)  # Update the phase
        test = SIMD[DType.bool, self.N](fill=False)
        rbd = self.rising_bool_detector.next(trig)

        for i in range(self.N):
            if (freq[i] > 0.0 and phase[i] < self.last_phase[i]) or (freq[i] < 0.0 and phase[i] > self.last_phase[i]):  # Check for an impulse (crossing the 0.5 threshold)
                test[i] = True
            elif rbd[i]:
                test[i] = True
                self.phasor.phase[i] = 0.0  # Reset phase on trigger
        self.last_phase = phase

        return test

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


    fn next(mut self: Dust, low: SIMD[DType.float64, self.N] = 100.0, high: SIMD[DType.float64, self.N] = 2000.0, trig: SIMD[DType.bool, self.N] = True) -> SIMD[DType.float64, self.N]:
        return self.next_bool(low, high, trig).cast[DType.float64]()

    @always_inline
    fn next_bool(mut self: Dust, low: SIMD[DType.float64, self.N] = 100.0, high: SIMD[DType.float64, self.N] = 2000.0, trig: SIMD[DType.bool, self.N] = True) -> SIMD[DType.bool, self.N]:
        """Generate the next dust noise sample."""
        rbd = self.rising_bool_detector.next(trig)

        var tick = self.impulse.next_bool(self.freq, trig)  # Update the phase
        var out = SIMD[DType.bool, self.N](fill=False)

        @parameter
        for i in range(self.N):
            if tick[i] or rbd[i]:
                self.freq[i] = random_exp_float64(low[i], high[i])
                out[i] = True
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
                self.history[j][i] = random_float64(0.1, 1.0)
        # Initialize history with random values

    fn __repr__(self) -> String:
        return String("LFNoise1")

    @always_inline
    fn next(mut self: LFNoise, freq: SIMD[DType.float64, self.N] = 100.0) -> SIMD[DType.float64, self.N]:
        """Generate the next low-frequency noise sample."""
        var trig_mask = SIMD[DType.bool, self.N](fill=False)
        var tick = self.impulse.next(freq, trig_mask)  # Update the phase

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
            return linear_interpp0, p1, self.impulse.phasor.phase)
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

struct OscBuffers(Movable, Copyable):
    var buffers: InlineArray[InlineArray[Float64, 16384], 7]  # List of all waveform buffers
    var last_phase: Float64  # Last phase value for interpolation
    var size: Int64
    var mask: Int64

    fn __init__(out self):
        self.size = 16384
        self.mask = self.size - 1
        self.buffers = InlineArray[InlineArray[Float64, 16384], 7](uninitialized=True)
        self.last_phase = 0.0  # Initialize last phase value
        
        self.init_sine()  # Initialize sine wave buffer

        self.init_triangle()  # Initialize triangle wave buffer using harmonics
        self.init_sawtooth()  # Initialize sawtooth wave buffer using harmonics
        self.init_square()  # Initialize square wave buffer using harmonics

        self.init_lf_triangle()  # Initialize triangle wave buffer
        self.init_lf_sawtooth()  # Initialize sawtooth wave buffer
        self.init_lf_square()  # Initialize square wave buffer

    # Build Wavetables:
    # =================
    @doc_private
    fn init_sine(mut self: OscBuffers):
        for i in range(self.size):
            self.buffers[0][i] = (sin(2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)))  # Precompute sine values

    @doc_private
    fn init_triangle(mut self: OscBuffers):
        # Construct triangle wave from sine harmonics
        # Triangle formula: 8/pi^2 * sum((-1)^(n+1) * sin(n*x) / n^2) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / (Float64(n) * Float64(n))
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 8/π² for correct amplitude
            self.buffers[4][i] = 8.0 / (3.141592653589793 * 3.141592653589793) * sample

    @doc_private
    fn init_sawtooth(mut self: OscBuffers):
        # Construct sawtooth wave from sine harmonics
        # Sawtooth formula: 2/pi * sum((-1)^(n+1) * sin(n*x) / n) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / Float64(n)
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 2/π for correct amplitude
            self.buffers[5][i] = 2.0 / 3.141592653589793 * sample

    @doc_private
    fn init_square(mut self: OscBuffers):
        # Construct square wave from sine harmonics
        # Square formula: 4/pi * sum(sin((2n-1)*x) / (2n-1)) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(2 * n - 1) * x) / Float64(2 * n - 1)
                sample += harmonic
            
            # Scale by 4/π for correct amplitude
            self.buffers[6][i] = 4.0 / 3.141592653589793 * sample

    @doc_private
    fn init_lf_triangle(mut self: OscBuffers):
        for i in range(self.size):
            if i < self.size // 2:
                self.buffers[1][i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Ascending part
            else:
                self.buffers[1][i] = 1.0 - 2.0 * (Float64(i) / Float64(self.size))  # Descending part

    @doc_private
    fn init_lf_sawtooth(mut self: OscBuffers):
        for i in range(self.size):
            self.buffers[2][i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Linear ramp from -1 to 1

    @doc_private
    fn init_lf_square(mut self: OscBuffers):
        for i in range(self.size):
            if i < self.size // 2:
                self.buffers[3][i] = 1.0  # First half is 1
            else:
                self.buffers[3][i] = -1.0  # Second half is -1

    @always_inline
    fn quadratic_interp_loc(self, x: Float64, buf_num: Int64) -> Float64:
        base_idx = Int64(x) & self.mask
        idx1 = (base_idx + 1) & self.mask
        idx2 = (base_idx + 2) & self.mask
        
        frac = x - Float64(Int64(x))
        
        ref buffer = self.buffers[buf_num]
        return quadratic_interp(buffer[base_idx], buffer[idx1], buffer[idx2], frac)

    @always_inline
    fn linear_interpself, x: Float64, buf_num: Int64) -> Float64:
        index = Int64(x) & self.mask
        index_next = (index + 1) & self.mask
        frac = x - Float64(Int64(x))
        
        ref buffer = self.buffers[buf_num]
        return buffer[index] + frac * (buffer[index_next] - buffer[index])
    
    @always_inline
    fn read_none(self, phase: Float64, buf_num: Int64) -> Float64:
        index = Int64(phase * Float64(self.size)) & self.mask
        
        return self.buffers[buf_num][index]

    @always_inline
    fn read_lin(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size))
        var value = self.linear_interpf_index, buf_num)
        return value

    @always_inline
    fn read_quadratic(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size))
        var value = self.quadratic_interp_loc(f_index, buf_num)
        return value

    fn read[interp: Int = 0](self, phase: Float64, osc_type: Int64 = 0) -> Float64:
        @parameter
        if interp == 0:
            return self.read_lin(phase, osc_type)  # Linear interpolation
        elif interp == 1:
            return self.read_quadratic(phase, osc_type)  # Quadratic interpolation
        else:
            return self.read_lin(phase, osc_type)  # Default to linear interpolation

    @always_inline
    fn read_sinc(self,phase: Float64, last_phase: Float64, channel: Int64) -> Float64:
        return self.sinc_interpolator.read_sinc(self, phase, last_phase, channel)

    fn __repr__(self) -> String:
        return String("OscBuffers(size=" + String(self.size) + ")")