from math import sin, floor
from random import random_float64
from .functions import *
from .MMMWorld_Module import MMMWorld, Interp
from .Buffer_Module import *
from .Filters import *
from .Oversampling import Oversampling
from .RisingBoolDetector_Module import RisingBoolDetector

struct Phasor[num_chans: Int = 1, os_index: Int = 0](Representable, Movable, Copyable):
    """Phasor Oscillator.

    An oscillator that generates a ramp waveform from 0.0 to 1.0. The phasor is the root of all oscillators in MMMAudio.
    
    The Phasor can act as a simple phasor with the .next() function. 
    
    However, it can also be an impulse with next_impulse() and a boolean impulse with next_bool().

    Parameters:
        num_chans: Number of channels.
        os_index: Oversampling index (0 = no oversampling, 1 = 2x, up to 4 = 16x). Phasor does not downsample its output, so oversampling is only useful when used as part of other oversampled oscillators.
    """
    var phase: SIMD[DType.float64, Self.num_chans]
    var freq_mul: Float64
    var rising_bool_detector: RisingBoolDetector[Self.num_chans]  # Track the last reset state
    var rising_bool_detector_impulse: RisingBoolDetector[Self.num_chans]  # Track the last reset state
    var world: World  # Pointer to the MMMWorld instance

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.world = world
        self.phase = SIMD[DType.float64, Self.num_chans](0.0)
        self.freq_mul = self.world[].os_multiplier[Self.os_index] / self.world[].sample_rate
        self.rising_bool_detector = RisingBoolDetector[Self.num_chans]()
        self.rising_bool_detector_impulse = RisingBoolDetector[Self.num_chans]()

    fn __repr__(self) -> String:
        return String("Phasor")

    @doc_private
    @always_inline
    fn _increment_phase(mut self: Phasor, freq: SIMD[DType.float64, self.num_chans]):
        self.phase += (freq * self.freq_mul)
        self.phase = self.phase - floor(self.phase)

    @doc_private
    @always_inline
    fn _increment_phase_impulse(mut self, freq: SIMD[DType.float64, self.num_chans], phase_offset: SIMD[DType.float64, self.num_chans] = 0.0) -> SIMD[DType.bool, Self.num_chans]:
        self.phase += (freq * self.freq_mul)
        fl = floor(self.phase)
        rbd = self.rising_bool_detector_impulse.next(abs(self.phase+phase_offset).gt(1.0))
        self.phase = self.phase - fl 
        return rbd

    @always_inline
    fn next(mut self: Phasor, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill=True)) -> SIMD[DType.float64, self.num_chans]:
        """Creates the next sample of the phasor output based on the inputs.

        Args:
          freq: Frequency of the phasor in Hz.
          phase_offset: Offsets the phase of the oscillator.
          trig: Trigger signal to reset the phase when switching from False to True.

        Returns:
            The next sample of the phasor output.
        """
        self._increment_phase(freq)
        
        var resets = self.rising_bool_detector.next(trig)
        self.phase = resets.select(0.0, self.phase)
        
        return (self.phase + phase_offset) % 1.0

    @always_inline
    fn next_bool(mut self, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill=True)) -> SIMD[DType.bool, self.num_chans]:
        """Increments the phasor and returns a boolean impulse when the phase wraps around from 1.0 to 0.0.

        Args:
          freq: Frequency of the phasor in Hz (default is 100.0).
          phase_offset: Offsets the phase of the oscillator (default is 0.0).
          trig: Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample).

        Returns:
            A boolean SIMD indicating True when the impulse occurs.
        """

        tick = self._increment_phase_impulse(freq, phase_offset)
        rbd = self.rising_bool_detector.next(trig)
        self.phase = rbd.select(0.0, self.phase)
        
        return (tick or rbd)

    @always_inline
    fn next_impulse(mut self, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill=   True)) -> SIMD[DType.float64, self.num_chans]:
        """Generates an impulse waveform where the output is 1.0 for one sample when the phase wraps around from 1.0 to 0.0, and 0.0 otherwise.

        Args:
          freq: Frequency of the phasor in Hz (default is 100.0).
          phase_offset: Offsets the phase of the oscillator (default is 0.0).
          trig: Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample).

        Returns:
            The next impulse sample as a Float64. 1.0 when the impulse occurs, 0.0 otherwise.
        """

        return self.next_bool(freq, phase_offset, trig).cast[DType.float64]()


struct Impulse[num_chans: Int = 1, os_index: Int = 0](Movable, Copyable):
    """Impulse Oscillator.

    An oscillator that outputs a 1.0 or True for one sample when the phase wraps around from 1.0 to 0.0.
    
    Impulse is essentially a wrapper around the Phasor oscillator that provides impulse-specific methods.

    Parameters:
        num_chans: Number of channels (default is 1).
        os_index: Oversampling index (0 = no oversampling, 1 = 2x, etc.; default is 0).
    """
    var phasor: Phasor[Self.num_chans, Self.os_index]  # Instance of the Phasor

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.phasor = Phasor[self.num_chans, Self.os_index](world)

    fn __repr__(self) -> String:
        return String("Impulse")

    @always_inline
    fn next_bool(mut self, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill=True)) -> SIMD[DType.bool, self.num_chans]:
         """Increments the phasor and returns a boolean impulse when the phase wraps around from 1.0 to 0.0.

        Args:
          freq: Frequency of the phasor in Hz (default is 100.0).
          phase_offset: Offsets the phase of the oscillator (default is 0.0).
          trig: Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample).

        Returns:
            A boolean SIMD indicating True when the impulse occurs.
        """

        return self.phasor.next_bool(freq, phase_offset, trig) 

    @always_inline
    fn next(mut self, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill= True)) -> SIMD[DType.float64, self.num_chans]:
        """Generates an impulse waveform where the output is 1.0 for one sample when the phase wraps around from 1.0 to 0.0, and 0.0 otherwise.

        Args:
          freq: Frequency of the phasor in Hz (default is 100.0).
          phase_offset: Offsets the phase of the oscillator (default is 0.0).
          trig: Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample).

        Returns:
            The next impulse sample as a Float64. 1.0 when the impulse occurs, 0.0 otherwise.
        """

        return self.phasor.next_impulse(freq, phase_offset, trig)

struct Osc[num_chans: Int = 1, interp: Int = Interp.linear, os_index: Int = 0](Representable, Movable, Copyable):
    """Wavetable Oscillator Core.

    A wavetable oscillator capable of all standard waveforms and also able to load custom wavetables. Capable of linear, cubic, quadratic, lagrange, or sinc interpolation. Also capable of [Oversampling](Oversampling.md).
    
    - Pure tones can be generated without oversampling or sinc interpolation.
    - When doing extreme modulation, best practice is to use sinc interpolation and an oversampling index of 1 (2x).
    - Try all the combinations of interpolation and oversampling to find the best tradeoff between quality and CPU usage for your application.

    Parameters:
        num_chans: Number of channels (default is 1).
        interp: Interpolation method. See [Interp](MMMWorld.md/#struct-interp) struct for options (default is Interp.linear).
        os_index: [Oversampling](Oversampling.md) index (0 = no oversampling, 1 = 2x, 2 = 4x, etc.; default is 0).
    """

    var phasor: Phasor[Self.num_chans, Self.os_index]  # Instance of the Phasor
    var world: World  # Pointer to the MMMWorld instance
    var oversampling: Oversampling[Self.num_chans, 2**Self.os_index]
    var last_phase: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.world = world
        self.phasor = Phasor[self.num_chans, Self.os_index](self.world)
        self.oversampling = Oversampling[self.num_chans, 2**Self.os_index](self.world)
        self.last_phase = SIMD[DType.float64, self.num_chans](0.0)

    fn __repr__(self) -> String:
        return String("Osc")

    @always_inline
    fn next(
            mut self: Osc, 
            freq: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](100.0), 
            phase_offset: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](0.0), 
            trig: Bool = False, 
            osc_type: SIMD[DType.int64, self.num_chans] = SIMD[DType.int64, self.num_chans](OscType.sine)
        ) -> SIMD[DType.float64, self.num_chans]:
        """
        Generate the next oscillator sample on a single waveform type. All inputs are SIMD types except trig, which is a scalar. This means that an oscillator can have num_chans different instances, each with its own frequency, phase offset, and waveform type, but they will all share the same trigger signal.

        Args:
            freq: Frequency of the oscillator in Hz.
            phase_offset: Offsets the phase of the oscillator (default is 0.0).
            trig: Trigger signal to reset the phase when switching from False to True (default is 0.0).
            osc_type: Type of waveform. See the OscType struct for options (default is OscType.sine). Best if provided as OscType.sine, OscType.triangle, etc.

        Returns:
            The next sample of the oscillator output.
        """
        var trig_mask = SIMD[DType.bool, self.num_chans](fill=trig)
            
        out = SIMD[DType.float64, self.num_chans](0.0)

        @parameter
        if Self.os_index == 0:
            
            # last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
            phase = self.phasor.next(freq, phase_offset, trig_mask)

            @parameter
            for chan in range(self.num_chans):
                out[chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=OscBuffersMask
                    ](
                        world = self.world,
                        data=self.world[].osc_buffers.buffers[osc_type[chan]],
                        f_idx=phase[chan] * OscBuffersSize,
                        prev_f_idx=self.last_phase[chan] * OscBuffersSize
                    )
            self.last_phase = phase
            return out
        else:
            @parameter
            for i in range(2**Self.os_index):
                
                # last_phase = self.phasor.phase  # Store the last phase for sinc interpolation
                phase = self.phasor.next(freq, phase_offset, trig_mask)

                sample = SIMD[DType.float64, self.num_chans](0.0)
                @parameter
                for chan in range(self.num_chans):
                    sample[chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=OscBuffersMask
                    ](
                        world = self.world,
                        data=self.world[].osc_buffers.buffers[osc_type[chan]],
                        f_idx=phase[chan] * OscBuffersSize,
                        prev_f_idx=self.last_phase[chan] * OscBuffersSize
                    )
                self.oversampling.add_sample(sample)  # Get the next sample from the Oscillator buffer using sinc interpolation
                self.last_phase = phase

            return self.oversampling.get_sample()

    # fn vwt_get_one_sample()

    @always_inline
    fn next_vwt(
            mut self, 
            freq: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](100.0), 
            phase_offset: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](0.0), 
            trig: Bool = False, 
            osc_types: List[Int64] = [OscType.sine,OscType.bandlimited_triangle,OscType.bandlimited_saw,OscType.bandlimited_square], 
            osc_frac: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](0.0)
        ) -> SIMD[DType.float64, self.num_chans]:
        """Variable Wavetable Oscillator using built-in waveforms. Generates the next oscillator sample on a variable 
        waveform where the output is interpolated between 
        different waveform types. All inputs are SIMD types except trig and osc_types, which are scalar. This 
        means that an oscillator can have num_chans different instances, each with its own frequency, phase offset, 
        and waveform type, but they will all share the same trigger signal and the same list of waveform types 
        to interpolate between.
        
        Args:
            freq: Frequency of the oscillator in Hz.
            phase_offset: Offsets the phase of the oscillator (default is 0.0).
            trig: Trigger signal to reset the phase when switching from False to True (default is 0.0).
            osc_types: List of waveform types ([OscType](MMMWorld.md/#struct-osctype)) to interpolate between (default is [OscType.sine,OscType.bandlimited_triangle,OscType.bandlimited_saw,OscType.bandlimited_square].
            osc_frac: Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first waveform in the osc_types list, 1.0 corresponds to the last waveform in the osc_types list, and values in between interpolate linearly between all waveforms in the list.
        
        Returns:
            The next sample of the oscillator output.
        """
        var trig_mask = SIMD[DType.bool, self.num_chans](fill=trig)

        var max_osc_frac = len(osc_types)-1

        var scaled_osc_frac = Float64(max_osc_frac) * min(osc_frac, 1.0) #can't use a modulus here

        var osc_type0: SIMD[DType.int64, self.num_chans] = SIMD[DType.int64, self.num_chans](scaled_osc_frac)
        var osc_type1 = SIMD[DType.int64, self.num_chans](osc_type0 + 1)
        osc_type0 = clip(osc_type0, 0,  max_osc_frac)
        osc_type1 = clip(osc_type1, 0, max_osc_frac)
        
        @parameter
        for i in range(self.num_chans):
            osc_type0[i] = osc_types[osc_type0[i]]
            osc_type1[i] = osc_types[osc_type1[i]]

        osc_frac_interp = scaled_osc_frac - floor(scaled_osc_frac)

        var sample0 = SIMD[DType.float64, self.num_chans](0.0)
        var sample1 = SIMD[DType.float64, self.num_chans](0.0)

        @parameter
        if Self.os_index == 0:
            # var last_phase = self.phasor.phase
            var phase = self.phasor.next(freq, phase_offset, trig_mask)
            @parameter
            for chan in range(self.num_chans):
                sample0[chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=OscBuffersMask
                    ](
                        world = self.world,
                        data=self.world[].osc_buffers.buffers[osc_type0[chan]],
                        f_idx=phase[chan] * OscBuffersSize,
                        prev_f_idx=self.last_phase[chan] * OscBuffersSize
                    )
                sample1[chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=OscBuffersMask
                    ](
                        world = self.world,
                        data=self.world[].osc_buffers.buffers[osc_type1[chan]],
                        f_idx=phase[chan] * OscBuffersSize,
                        prev_f_idx=self.last_phase[chan] * OscBuffersSize
                    )
            self.last_phase = phase
            return linear_interp(sample0, sample1, osc_frac_interp)
        else:
            @parameter
            for i in range(2**Self.os_index):
                # var last_phase = self.phasor.phase
                var phase = self.phasor.next(freq, phase_offset, trig_mask)
                @parameter
                for chan in range(self.num_chans):
                    sample0[chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=OscBuffersMask
                    ](
                        world = self.world,
                        data=self.world[].osc_buffers.buffers[osc_type0[chan]],
                        f_idx=phase[chan] * OscBuffersSize,
                        prev_f_idx=self.last_phase[chan] * OscBuffersSize
                    )
                    sample1[chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=OscBuffersMask
                    ](
                        world = self.world,
                        data=self.world[].osc_buffers.buffers[osc_type1[chan]],
                        f_idx=phase[chan] * OscBuffersSize,
                        prev_f_idx=self.last_phase[chan] * OscBuffersSize
                    )
                self.oversampling.add_sample(linear_interp(sample0, sample1, osc_frac_interp))
                self.last_phase = phase
            return self.oversampling.get_sample()
    
    @always_inline
    fn next_vwt(
            mut self: Osc, 
            ref buffer: Buffer, 
            freq: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](100.0), 
            phase_offset: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](0.0), 
            trig: Bool = False, 
            osc_frac: SIMD[DType.float64, self.num_chans] = SIMD[DType.float64, self.num_chans](0.0)
        ) -> SIMD[DType.float64, self.num_chans]:
        """Variable Wavetable Oscillator that interpolates over a loaded Buffer.
        Generates the next oscillator sample on a variable waveform where the output is interpolated between 
        different different channels of a provided Buffer.
        
        Args:
            buffer: Reference to a Buffer containing the waveforms to interpolate between.
            freq: Frequency of the oscillator in Hz.
            phase_offset: Offsets the phase of the oscillator (default is 0.0).
            trig: Trigger signal to reset the phase when switching from False to True (default is 0.0). All waveforms will reset together.
            osc_frac: Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first channel in the input buffer, 1.0 corresponds to the last channel in the input buffer, and values in between interpolate linearly between all channels in the buffer.
        """
        var trig_mask = SIMD[DType.bool, self.num_chans](fill=trig)

        var max_osc_frac = buffer.num_chans - 1

        var chan0_fl = Float64(max_osc_frac) * min(osc_frac, 1.0) #can't use a modulus here

        var buf_chan0: SIMD[DType.int64, self.num_chans] = SIMD[DType.int64, self.num_chans](chan0_fl)
        var buf_chan1 = SIMD[DType.int64, self.num_chans](buf_chan0 + 1)

        scaled_osc_frac = chan0_fl - floor(chan0_fl)

        var sample0 = SIMD[DType.float64, self.num_chans](0.0)
        var sample1 = SIMD[DType.float64, self.num_chans](0.0)

        @parameter
        if Self.os_index == 0:
            # var last_phase = self.phasor.phase
            var phase = self.phasor.next(freq, phase_offset, trig_mask)
            @parameter
            for out_chan in range(self.num_chans):
                sample0[out_chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=0
                    ](
                        world = self.world,
                        data=buffer.data[buf_chan0[out_chan]],
                        f_idx=phase[out_chan] * buffer.num_frames_f64,
                        prev_f_idx=self.last_phase[out_chan] * buffer.num_frames_f64
                    )
                sample1[out_chan] = ListInterpolator.read[
                        interp=self.interp,
                        bWrap=True,
                        mask=0
                    ](
                        world = self.world,
                        data=buffer.data[buf_chan1[out_chan]],
                        f_idx=phase[out_chan] * buffer.num_frames_f64,
                        prev_f_idx=self.last_phase[out_chan] * buffer.num_frames_f64
                    )
            self.last_phase = phase
            return linear_interp(sample0, sample1, scaled_osc_frac)
        else:
            comptime times_os_int = 2**Self.os_index
            @parameter
            for i in range(times_os_int):
                # var last_phase = self.phasor.phase
                var phase = self.phasor.next(freq, phase_offset, trig_mask)
                @parameter
                for out_chan in range(self.num_chans):
                    sample0[out_chan] = ListInterpolator.read[
                            interp=self.interp,
                            bWrap=True,
                            mask=0
                        ](
                            world = self.world,
                            data=buffer.data[buf_chan0[out_chan]],
                            f_idx=phase[out_chan] * buffer.num_frames_f64,
                            prev_f_idx=self.last_phase[out_chan] * buffer.num_frames_f64
                        )
                    sample1[out_chan] = ListInterpolator.read[
                            interp=self.interp,
                            bWrap=True,
                            mask=0
                        ](
                            world = self.world,
                            data=buffer.data[buf_chan1[out_chan]],
                            f_idx=phase[out_chan] * buffer.num_frames_f64,
                            prev_f_idx=self.last_phase[out_chan] * buffer.num_frames_f64
                        )
                self.oversampling.add_sample(linear_interp(sample0, sample1, scaled_osc_frac))
                self.last_phase = phase
            return self.oversampling.get_sample()


struct SinOsc[num_chans: Int = 1, os_index: Int = 0] (Representable, Movable, Copyable):
    """A sine wave oscillator.
    
    This is a convenience struct as internally it uses [Osc](Oscillators.md/#struct-osc) and indicates `osc_type = OscType.sine`.

    Parameters:
        num_chans: Number of channels (default is 1).
        os_index: Oversampling index (0 = no oversampling, 1 = 2x, etc.; default is 0).

    Args:
        world: Pointer to the MMMWorld instance.
    """

    var osc: Osc[Self.num_chans, Interp.linear, Self.os_index]  # Instance of the Oscillator

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.osc = Osc[self.num_chans, Interp.linear, Self.os_index](world)  # Initialize the Oscillator with the world instance

    fn __repr__(self) -> String:
        return String("SinOsc")

    @always_inline
    fn next(mut self: SinOsc, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: Bool = False, interp: Int64 = 0) -> SIMD[DType.float64, self.num_chans]:
        return self.osc.next(freq, phase_offset, trig, 0)

struct LFSaw[num_chans: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency sawtooth oscillator.
    
    This oscillator generates a non-bandlimited sawtooth waveform. It is useful for modulation, but should be avoided for audio-rate synthesis due to comptimeing.

    Outputs values between 0.0 and 1.0.

    Parameters:
        num_chans: Number of channels (default is 1).
    """

    var phasor: Phasor[Self.num_chans]  # Instance of the Oscillator

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.phasor = Phasor[self.num_chans](world)  # Initialize the Phasor with the world instance

    fn __repr__(self) -> String:
        return String("LFSaw")

    @always_inline
    fn next(mut self: LFSaw, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: Bool = False) -> SIMD[DType.float64, self.num_chans]:
        """Generate the next sawtooth wave sample.
        
        Args:
            freq: Frequency of the sawtooth wave in Hz.
            phase_offset: Offsets the phase of the oscillator (default is 0.0).
            trig: Trigger signal to reset the phase when switching from False to True (default is 0.0).
        
        """

        var trig_mask = SIMD[DType.bool, self.num_chans](fill=trig)
        return (self.phasor.next(freq, phase_offset, trig_mask) * 2.0) - 1.0

struct LFSquare[num_chans: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency square wave oscillator.
    
    Creates a non-band-limited square wave. Outputs values of -1.0 or 1.0. Useful for modulation, but should be avoided for audio-rate synthesis due to comptimeing.

    Parameters:
        num_chans: Number of channels (default is 1).
    """

    var phasor: Phasor[Self.num_chans]  # Instance of the Oscillator

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.phasor = Phasor[self.num_chans](world)  # Initialize the Phasor with the world instance

    fn __repr__(self) -> String:
        return String("LFSquare")

    @always_inline
    fn next(mut self: LFSquare, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: Bool = False) -> SIMD[DType.float64, self.num_chans]:
        """Generate the next square wave sample.

        Args:
            freq: Frequency of the square wave in Hz.
            phase_offset: Offsets the phase of the oscillator (default is 0.0).
            trig: Trigger signal to reset the phase when switching from False to True (default is 0.0).
        """
        var trig_mask = SIMD[DType.bool, self.num_chans](fill=trig)
        return -1.0 if self.phasor.next(freq, phase_offset, trig_mask) < 0.5 else 1.0

struct LFTri[num_chans: Int = 1] (Representable, Movable, Copyable):
    """A low-frequency triangle wave oscillator.
    
    This oscillator generates a triangle wave at audio rate. It is useful for 
    modulation, but should be avoided for audio-rate synthesis due to comptimeing.

    Parameters:
        num_chans: Number of channels (default is 1).
    """

    var phasor: Phasor[Self.num_chans]  # Instance of the Oscillator

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.phasor = Phasor[self.num_chans](world)  # Initialize the Phasor with the world instance

    fn __repr__(self) -> String:
        return String("LFTri")

    @always_inline
    fn next(mut self: LFTri, freq: SIMD[DType.float64, self.num_chans] = 100.0, phase_offset: SIMD[DType.float64, self.num_chans] = 0.0, trig: Bool = False) -> SIMD[DType.float64, self.num_chans]:
        """Generate the next triangle wave sample.

        Args:
            freq: Frequency of the triangle wave in Hz.
            phase_offset: Offsets the phase of the oscillator.
            trig: Trigger signal to reset the phase when switching from False to True.
        """

        var trig_mask = SIMD[DType.bool, self.num_chans](fill=trig)
        return (abs((self.phasor.next(freq, phase_offset-0.25, trig_mask) * 4.0) - 2.0) - 1.0)

struct Dust[num_chans: Int = 1] (Representable, Movable, Copyable):
    """A dust noise oscillator that generates random impulses at random intervals.
    
    Dust has a Phasor as its core, and the frequency of the Phasor is randomly changed each time an impulse is generated. This allows the Dust to be used in multiple ways. It can be used as a simple random impulse generator, or the user can use the get_phase() method to get the current phase of the internal Phasor and use that phase to drive other oscillators or processes. The user can also set the phase of the internal Phasor using the set_phase() method, allowing for more complex interactions.

    Parameters:
        num_chans: Number of channels.
    """
    var impulse: Phasor[Self.num_chans]
    var freq: SIMD[DType.float64, Self.num_chans]

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.impulse = Phasor[Self.num_chans](world)
        # this will cause all Dusts to start at a different phase
        for i in range(self.num_chans):
            self.impulse.phase[i] = random_float64(0.0, 1.0)
        self.freq = SIMD[DType.float64, Self.num_chans](1.0)

    fn __repr__(self) -> String:
        return String("Dust")

    fn next(mut self: Dust, low: SIMD[DType.float64, self.num_chans] = 100.0, high: SIMD[DType.float64, self.num_chans] = 2000.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill= False)) -> SIMD[DType.float64, self.num_chans]:
        """Generate the next dust noise sample.
        
        Args:
            low: Lower bound for the random frequency range.
            high: Upper bound for the random frequency range.
            trig: Trigger signal to reset the phase when switching from False to True.

        Returns:
            The next dust noise sample as a Float64. Will be 1.0 when an impulse occurs, 0.0 otherwise.
        """
        return self.next_bool(low, high, trig).cast[DType.float64]()

    @always_inline
    fn next_bool(mut self: Dust, low: SIMD[DType.float64, self.num_chans] = 100.0, high: SIMD[DType.float64, self.num_chans] = 2000.0, trig: SIMD[DType.bool, self.num_chans] = SIMD[DType.bool, self.num_chans](fill= False)) -> SIMD[DType.bool, self.num_chans]:
        """Generate the next dust noise sample as a boolean impulse.
        
        Args:
            low: Lower bound for the random frequency range.
            high: Upper bound for the random frequency range.
            trig: Trigger signal to reset the phase when switching from False to True.

        Returns:
            The next dust noise sample as a boolean SIMD. Will be True when an impulse occurs, False otherwise.
        """

        var tick = self.impulse.next_bool(self.freq, 0, trig)  # Update the phase

        @parameter
        for i in range(self.num_chans):
            if tick[i]:
                self.freq[i] = random_float64(low[i], high[i])

        return tick

    fn get_phase(self) -> SIMD[DType.float64, self.num_chans]:
        return self.impulse.phase

    fn set_phase(mut self, phase: SIMD[DType.float64, self.num_chans]):
        self.impulse.phase = phase

struct LFNoise[num_chans: Int = 1, interp: Int = Interp.cubic](Representable, Movable, Copyable):
    """Low-frequency interpolating noise generator.
    
    With stepped (none), linear, or cubic interpolation.

    Parameters:
        num_chans: Number of channels.
        interp: Interpolation method. Options are Interp.none (stepped), Interp.linear, Interp.cubic.
    """
    var world: World  # Pointer to the MMMWorld instance
    var impulse: Phasor[Self.num_chans]

    # Cubic inerpolation only needs 4 points, but it needs to know the true previous point so the history
    # needs an extra point: the 4 for interpolation, plus the point that is just changed
    var history: List[SIMD[DType.float64, Self.num_chans]]# used for interpolation

    # history_index: the index of the history list that the impulse's phase is moving *away* from
    # phase is moving *towards* history_index + 1
    var history_index: List[Int8]

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.world = world
        self.history_index = [0 for _ in range(self.num_chans)]
        self.impulse = Phasor[Self.num_chans](world)
        self.history = [SIMD[DType.float64, Self.num_chans](0.0) for _ in range(5)]
        for i in range(Self.num_chans):
            for j in range(len(self.history)):
                self.history[j][i] = random_float64(0.1, 1.0)
        # Initialize history with random values

    fn __repr__(self) -> String:
        return String("LFNoise1")

    @always_inline
    fn next(mut self: LFNoise, freq: SIMD[DType.float64, self.num_chans] = 100.0) -> SIMD[DType.float64, self.num_chans]:
        """Generate the next low-frequency noise sample.
        
        Args:
            freq: Frequency of the noise in Hz.

        Returns:
            The next sample as a Float64.
        """
        # var trig_mask = SIMD[DType.bool, self.num_chans](fill=False)
        var tick = self.impulse.next_bool(freq)  # Update the phase

        @parameter
        for i in range(self.num_chans):
            if tick[i]:  # If an impulse is detected
                # advance the history index
                self.history_index[i] = (self.history_index[i] + 1) % len(self.history)

            # so don't change that one, cubic interp needs to know that, so we'll change 
            # history_index - 2 (but, again, computed differently to avoid negative indices) so
            # the next time we wrap around to that part of the history list it will be a new random value
            self.history[(self.history_index[i] + (len(self.history) - 2)) % len(self.history)][i] = random_float64(-1.0, 1.0)

        @parameter
        if Self.interp == Interp.none:
            p0 = SIMD[DType.float64, self.num_chans](0.0)
            @parameter
            for i in range(self.num_chans):
                p0[i] = self.history[(self.history_index[i] + 1) % len(self.history)][i]
            return p0
        elif Self.interp == Interp.linear:
            # Linear interpolation between last and next value
            p0 = SIMD[DType.float64, self.num_chans](0.0)
            p1 = SIMD[DType.float64, self.num_chans](0.0)
            @parameter
            for i in range(Self.num_chans):
                p0[i] = self.history[self.history_index[i]][i]
                p1[i] = self.history[(self.history_index[i] + 1) % len(self.history)][i]
            return linear_interp(p0, p1, self.impulse.phase)
        else:
            p0 = SIMD[DType.float64, self.num_chans](0.0)
            p1 = SIMD[DType.float64, self.num_chans](0.0)
            p2 = SIMD[DType.float64, self.num_chans](0.0)
            p3 = SIMD[DType.float64, self.num_chans](0.0)
            @parameter
            for i in range(self.num_chans):
                p0[i] = self.history[(self.history_index[i] + (len(self.history) - 1)) % len(self.history)][i]
                p1[i] = self.history[self.history_index[i]][i]
                p2[i] = self.history[(self.history_index[i] + 1) % len(self.history)][i]
                p3[i] = self.history[(self.history_index[i] + 2) % len(self.history)][i]
            # Cubic interpolation
            return cubic_interp(p0, p1, p2, p3, self.impulse.phase)

struct Sweep[num_chans: Int = 1](Representable, Movable, Copyable):
    """A phase accumulator.
    
    Phase accumulator that sweeps from 0 up to inf at a given frequency, resetting on trigger.

    Parameters:
        num_chans: Number of channels.
    """

    var phase: SIMD[DType.float64, Self.num_chans]
    var freq_mul: Float64
    var rising_bool_detector: RisingBoolDetector[Self.num_chans]  # Track the last reset state
    var world: World  # Pointer to the MMMWorld instance

    fn __init__(out self, world: World):
        """

        Args:
            world: Pointer to the MMMWorld instance.
        """
        self.world = world
        self.phase = SIMD[DType.float64, Self.num_chans](0.0)
        self.freq_mul = 1.0 / self.world[].sample_rate
        self.rising_bool_detector = RisingBoolDetector[Self.num_chans]()

    fn __repr__(self) -> String:
        return String("Sweep")
        
    @always_inline
    fn next(mut self, freq: SIMD[DType.float64, self.num_chans] = 100.0, trig: SIMD[DType.bool, self.num_chans] = False) -> SIMD[DType.float64, self.num_chans]:
        """Generate the next sweep sample.

        Args:
            freq: Frequency of the sweep in Hz.
            trig: Trigger signal to reset the phase when switching from False to True (default is all False).

        Returns:
            The next sample as a Float64.
        """

        self.phase += (freq * self.freq_mul)

        var resets = self.rising_bool_detector.next(trig)

        @parameter
        for i in range(self.num_chans):
            if resets[i]:
                self.phase[i] = 0.0

        return self.phase

comptime OscBuffersSize: Int = 16384  # 2^14
comptime OscBuffersMask: Int = 16383  # 2^14 - 1

@doc_private
struct OscBuffers(Movable, Copyable):
    var buffers: InlineArray[List[Float64],7]

    fn at_phase[osc_type: Int, interp: Int = Interp.none](self, world: World, phase: Float64, prev_phase: Float64 = 0) -> Float64:
        return ListInterpolator.read[
            interp=interp,
            bWrap=True,
            mask=OscBuffersMask
        ](
            world=world,
            data=self.buffers[osc_type],
            f_idx=phase * OscBuffersSize,
            prev_f_idx=prev_phase * OscBuffersSize
        )

    @doc_private
    fn __init__(out self):
        self.buffers = InlineArray[List[Float64],7](fill=List[Float64](length=OscBuffersSize, fill=0.0))
        
        self.init_sine()  # Initialize sine wave buffer

        self.init_lf_triangle()  # Initialize triangle wave buffer
        self.init_lf_sawtooth()  # Initialize sawtooth wave buffer
        self.init_lf_square()  # Initialize square wave buffer

        self.init_triangle()  # Initialize triangle wave buffer using harmonics
        self.init_sawtooth()  # Initialize sawtooth wave buffer using harmonics
        self.init_square()  # Initialize square wave buffer using harmonics

    # Build Wavetables:
    # =================
    @doc_private
    fn init_sine(mut self):
        for i in range(OscBuffersSize):
            v = sin(2.0 * 3.141592653589793 * Float64(i) / Float64(OscBuffersSize))
            self.buffers[0][i] = v

    @doc_private
    fn init_lf_triangle(mut self):
        for i in range(OscBuffersSize):
            val = Float64(i) / Float64(OscBuffersSize) * 4.0
            if val < 1.0:
                self.buffers[1][i] = linlin(val, 0.0, 1.0, 0.0, 1.0)  # Ascending part
            elif val < 3.0:
                self.buffers[1][i] = linlin(val, 1.0, 3.0, 1.0, -1.0)  # Descending part
            else:
                self.buffers[1][i] = linlin(val, 3.0, 4.0, -1.0, 0.0)  # Ascending part

    @doc_private
    fn init_lf_sawtooth(mut self):
        for i in range(OscBuffersSize):
            self.buffers[2][i] = 2.0 * (Float64(i) / Float64(OscBuffersSize)) - 1.0  # Linear ramp from -1 to 1

    @doc_private
    fn init_lf_square(mut self):
        for i in range(OscBuffersSize):
            if i < OscBuffersSize // 2:
                self.buffers[3][i] = 1.0  # First half is 1
            else:
                self.buffers[3][i] = -1.0  # Second half is -1

    @doc_private
    fn init_triangle(mut self):
        # Construct triangle wave from sine harmonics
        # Triangle formula: 8/pi^2 * sum((-1)^(n+1) * sin(n*x) / n^2) for n=1 to 512
        for i in range(OscBuffersSize):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(OscBuffersSize)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(2 * n - 1) * x) / (Float64(2 * n - 1) * Float64(2 * n - 1))
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic

                sample += harmonic
            
            # Scale by 8/π² for correct amplitude
            self.buffers[4][i] = 8.0 / (3.141592653589793 * 3.141592653589793) * sample

    @doc_private
    fn init_square(mut self):
        # Construct square wave from sine harmonics
        # Square formula: 4/pi * sum(sin((2n-1)*x) / (2n-1)) for n=1 to 512
        for i in range(OscBuffersSize):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(OscBuffersSize)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(2 * n - 1) * x) / Float64(2 * n - 1)
                sample += harmonic
            
            # Scale by 4/π for correct amplitude
            self.buffers[6][i] = 4.0 / 3.141592653589793 * sample

    @doc_private
    fn init_sawtooth(mut self):
        # Construct sawtooth wave from sine harmonics
        # Sawtooth formula: 2/pi * sum((-1)^(n+1) * sin(n*x) / n) for n=1 to 512
        for i in range(OscBuffersSize):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(OscBuffersSize)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / Float64(n)
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 2/π for correct amplitude
            self.buffers[5][i] = 2.0 / 3.141592653589793 * sample

    fn __repr__(self) -> String:
        return String("OscBuffers(size=" + String(OscBuffersSize) + ")")