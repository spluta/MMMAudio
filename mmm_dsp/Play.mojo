from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_dsp.SoundFile import *
from mmm_src.MMMWorld import *
from .Osc import Dust, Impulse
from mmm_utils.functions import *
from .Pan import Pan2
from mmm_dsp.Filters import DCTrap
from mmm_utils.RisingBoolDetector import RisingBoolDetector
from time import time
from utils import Variant

alias Readable = Variant[List[Float64], List[List[Float64]], SoundFile]

struct Play(Representable, Movable, Copyable):
    var impulse: Impulse  # Current phase of the buffer
    var done: Bool
    var w: UnsafePointer[MMMWorld]  
    var rising_bool_detector: RisingBoolDetector
    var start_frame: Int64 
    var reset_phase_point: Float64
    var phase_offset: Float64  # Offset for the phase calculation

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        """ 
        
        Args:
            w: pointer to the MMMWorld instance.
        """

        self.w = w
        self.impulse = Impulse(w)
        self.done = True
        self.rising_bool_detector = RisingBoolDetector()

        self.start_frame = 0
        self.reset_phase_point = 0.0
        self.phase_offset = 0.0

    fn __repr__(self) -> String:
        return String("Play")

    # [TODO]: change "num_chans" to "num_outs"
    @always_inline
    fn next[num_chans: Int = 1, interp: Int = Interp.linear](mut self, data: Readable, rate: Float64 = 1, loop: Bool = True, trig: Bool = True, start_frame: Int64 = 0, var num_frames: Int64 = -1, start_chan: Int64 = 0) -> SIMD[DType.float64, num_chans]: 
        """Get the next sample from an audio buffer (Buffer).

        Args:
            data: The audio data to read from (List[Float64]).
            rate: The playback rate. 1 is the normal speed of the buffer.
            loop: Whether to loop the buffer (default: True).
            trig: Trigger starts the synth at start_frame (default: 1.0).
            start_frame: The start frame for playback (default: 0) upon receiving a trigger.
            num_frames: The end frame for playback (default: -1 means to the end of the buffer).
            start_chan: The start channel for multi-channel buffers (default: 0).

        Returns:
            The next sample(s) from the buffer as a SIMD vector.
        """

        # [TODO] I think we need to make sure these are within valid ranges:
        # * start_frame 
        # * start_chan
        # * N in correspondence with start_chan and data channels
        # * num_frames in correspondence with start_frame and data length

        out = SIMD[DType.float64, num_chans](0.0)

        if self.done:
            return out  # Return zeros if done

        # Determine Length of the Data
        # ============================
        data_len_f: Float64 = 0.0
        sample_rate: Float64 = 0.0

        if data.isa[List[Float64]]():
            data_len_f = Float64(len(data[List[Float64]]))
            sample_rate = self.w[].sample_rate
        elif data.isa[List[List[Float64]]]() :
            data_len_f = Float64(len(data[List[List[Float64]]][0]))
            sample_rate = self.w[].sample_rate
        elif data.isa[SoundFile]():
            data_len_f = Float64(data[SoundFile].num_frames)
            sample_rate = data[SoundFile].sample_rate

        # Check for Trigger and if so, Update Values
        # ==========================================
        if self.rising_bool_detector.next(trig) and data_len_f > 0.0:
            self.done = False  # Reset done flag on trigger
            self.start_frame = start_frame  # Set start frame
            self.phase_offset = Float64(self.start_frame) / data_len_f  
            self.reset_phase_point = Float64(num_frames) / data_len_f  

        # Use Values to Calculate Frequency and Advance Phase
        # ===================================================
        freq = rate / (data_len_f / sample_rate)  # Calculate step size based on rate and sample rate
        # keep previous phase for sinc interp
        prev_phase = (self.impulse.phasor.phase + self.phase_offset) % 1.0
        # advance phase
        eor = self.impulse.next_bool(freq, trig = trig)

        if loop:
            # Wrap Phase
            if self.impulse.phasor.phase >= self.reset_phase_point:
                self.impulse.phasor.phase -= self.reset_phase_point
            return self.return_sample[num_chans=num_chans, interp=interp](data, prev_phase, data_len_f, start_chan)
        else:
            # Not in Loop Mode
            if trig: eor = False
            phase = self.impulse.phasor.phase
            # [TODO] I feel like it might not be necessary to check *all* these?
            if phase >= 1.0 or phase < 0.0 or eor or phase >= self.reset_phase_point:
                self.done = True  # Set done flag if phase is out of bounds
                return 0.0
            else:
                return self.return_sample[num_chans=num_chans, interp=interp](data, prev_phase, data_len_f, start_chan)

    @doc_private
    @always_inline
    fn return_sample[num_chans: Int, interp: Int](self, data: Readable, prev_phase: Float64, data_len_f: Float64, start_chan: Int64) -> SIMD[DType.float64, num_chans]:
        if data.isa[List[Float64]]():
            return self.get_sample[num_chans,interp](data[List[Float64]], prev_phase, data_len_f)
        elif data.isa[List[List[Float64]]]() :
            return self.get_sample[num_chans,interp](data[List[List[Float64]]], prev_phase, data_len_f, start_chan)
        elif data.isa[SoundFile]():
            return self.get_sample[num_chans,interp](data[SoundFile].data, prev_phase, data_len_f, start_chan)
        else:
            print("Play.mojo: Unsupported data type in return_samples")
            return SIMD[DType.float64, num_chans](0.0)

    @doc_private
    @always_inline
    fn get_sample[num_chans: Int, interp: Int](self, data: List[Float64], prev_phase: Float64, data_len_f: Float64) -> SIMD[DType.float64, num_chans]:
        
        v = ListFloat64Reader.read[interp=interp,bWrap=False](
                w=self.w,
                data=data,
                f_idx=((self.impulse.phasor.phase + self.phase_offset) % 1.0) * data_len_f,
                prev_f_idx=prev_phase * data_len_f
            )

        out = SIMD[DType.float64, num_chans](v)
        return out

    @doc_private
    @always_inline
    fn get_sample[num_chans: Int, interp: Int](self, data: List[List[Float64]], prev_phase: Float64, data_len_f: Float64, start_chan: Int64) -> SIMD[DType.float64, num_chans]:
        
        out = SIMD[DType.float64, num_chans](0.0)
        
        @parameter
        for out_chan in range(num_chans):
            out[out_chan] = ListFloat64Reader.read[interp=interp,bWrap=False](
                w=self.w,
                data=data[(out_chan + start_chan) % len(data)], # wrap around channels
                f_idx=((self.impulse.phasor.phase + self.phase_offset) % 1.0) * data_len_f,
                prev_f_idx=prev_phase * data_len_f
            )

        return out

@always_inline
fn determine_sample_rate(data: Readable, w: UnsafePointer[MMMWorld]) -> Float64:

    if data.isa[SoundFile]():
        return data[SoundFile].sample_rate
    else:
        return w[].sample_rate

struct Grain(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var start_frame: Int64
    var num_frames: Int64  
    var rate: Float64  
    var pan: Float64  
    var gain: Float64 
    var rising_bool_detector: RisingBoolDetector
    var panner: Pan2 
    var play_buf: Play
    var win_phase: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld], num_chans: Int64 = 2):
        self.w = w  

        self.start_frame = 0
        self.num_frames = 0
        self.rate = 1.0
        self.pan = 0.5 
        self.gain = 1.0
        self.rising_bool_detector = RisingBoolDetector()
        self.panner = Pan2(w)  
        self.play_buf = Play(w)
        self.win_phase = 0.0


    fn __repr__(self) -> String:
        return String("Grain")

    @always_inline
    fn next_pan[N: Int = 1, win_type: Int = WindowType.hann](mut self, read buffer: Readable, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        
        var sample = self.next[N=N, win_type=win_type](buffer, start_chan, trig, rate, start_frame, duration, pan, gain)

        @parameter
        if N == 1:
            return self.panner.next(sample[0], self.pan)  # Return the output samples
        else:
            return SIMD[DType.float64, 2](sample[0], sample[1])  # Return the output samples

    # N can only be 1 (default) or 2
    # [TODO]: add interp parameter
    @always_inline
    fn next[N: Int = 1, win_type: Int = 0](mut self, read buffer: Readable, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, N]:

        if self.rising_bool_detector.next(trig):
            self.start_frame = start_frame
            self.num_frames =  Int64(duration * determine_sample_rate(buffer, self.w) * rate)  # Calculate end frame based on duration
            self.rate = rate
            self.gain = gain
            self.pan = pan

        sample = self.play_buf.next[num_chans=N,interp=Interp.linear](buffer, self.rate, False, trig, self.start_frame, self.num_frames, start_chan) # Get samples from Play

        # Get the current phase of the Play
        # [TODO]: I don't understand this if statement
        if self.play_buf.reset_phase_point > 0.0:
            self.win_phase = self.play_buf.impulse.phasor.phase / self.play_buf.reset_phase_point  
        else:
            self.win_phase = 0.0  # Use the phase

        win = self.w[].windows.at_phase[WindowType.hann](self.w, self.win_phase)

        # this only works with 1 or 2 channels, if you try to do more, it will just return 2 channels 
        # [TODO]: Either make this work with multichannels or document this limitation
        sample = sample * win * self.gain
        
        return sample

struct TGrains[max_grains: Int = 5](Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.
    """
    var grains: List[Grain]  
    var w: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector 
    var trig: Bool

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(max_grains):
            self.grains.append(Grain(w, 2))
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
    
    fn __repr__(self) -> String:
        return String("TGrains")

    @always_inline
    fn next[N: Int = 1, win_type: Int = WindowType.hann](mut self, read buffer: Readable, buf_chan: Int = 0, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0, duration: Float64 = 0.1, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        """Generate the next set of grains.
        
        Args:.
            buffer: Audio buffer containing the source sound.
            trig: Trigger signal (>0 to start a new grain).
            rate: Playback rate of the grains (1.0 = normal speed).
            start_frame: Starting frame position in the buffer.
            duration: Duration of each grain in seconds.
            pan: Panning position from -1.0 (left) to 1.0 (right).
            gain: Amplitude scaling factor for the grains.

        Returns:
            List of output samples for all channels.
        """

        if self.rising_bool_detector.next(trig):
            self.counter += 1  # Increment the counter on trigger
            if self.counter >= max_grains:
                self.counter = 0  # Reset counter if it exceeds the number of grains

        out = SIMD[DType.float64, 2](0.0, 0.0)
        @parameter
        for i in range(max_grains):
            b = i == self.counter and self.rising_bool_detector.state
            out += self.grains[i].next_pan[N=N,win_type=win_type](buffer, buf_chan, b, rate, start_frame, duration, pan, gain)

        self.w[].print("TGrains next sample: ", out[0], ",", out[1])

        return out

struct PitchShift[overlaps: Int = 4](Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.

    Parameters:
        overlaps: Number of overlapping grains.

    Args:
        w: Pointer to the MMMWorld instance.
        buf_dur: Duration of the internal buffer in seconds.


    """
    var grains: List[Grain]  
    var w: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector
    var trig: Bool
    var buffer: List[Float64]
    var write_head: Int64
    var impulse: Dust
    var pitch_ratio: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld], buf_dur: Float64 = 1.0):
        """ 
            w: pointer to the MMMWorld instance.
            buf_dur: duration of the internal buffer in seconds.
        """
        self.w = w  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(overlaps+2):
            self.grains.append(Grain(w)) 
            
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
        self.buffer = List[Float64](length=Int(buf_dur * self.w[].sample_rate),fill=0.0)  # Empty buffer to be set later
        self.write_head = 0
        self.impulse = Dust(w)
        self.pitch_ratio = 1.0
    
    fn __repr__(self) -> String:
        return String("TGrains")

    # PitchShift.ar(in: 0.0, windowSize: 0.2, pitchRatio: 1.0, pitchDispersion: 0.0, timeDispersion: 0.0, mul: 1.0, add: 0.0)

    @always_inline
    fn next[win_type: Int = WindowType.hann](mut self, in_sig: Float64, win_size: Float64 = 0.2, pitch_ratio: Float64 = 1.0, pitch_dispersion: Float64 = 0.0, time_dispersion: Float64 = 0.0, gain: Float64 = 1.0) -> Float64:
        """Generate the next set of grains.
        
        Parameters:
            win_type: Type of window to use (default is Hann window).

        Args:.
            buffer: Audio buffer containing the source sound.
            trig: Trigger signal (>0 to start a new grain).
            rate: Playback rate of the grains (1.0 = normal speed).
            start_frame: Starting frame position in the buffer.
            duration: Duration of each grain in seconds.
            pan: Panning position from -1.0 (left) to 1.0 (right).
            gain: Amplitude scaling factor for the grains.

        Returns:
            List of output samples for all channels.
        """

        self.buffer[self.write_head] = in_sig  # Write the input signal into the buffer
        self.write_head = (self.write_head + 1) % len(self.buffer)
        alias overlaps_plus_2 = overlaps + 2

        trig_rate = overlaps / win_size
        trig = self.rising_bool_detector.next(
            self.impulse.next_bool(trig_rate*(1-time_dispersion), trig_rate*(1+time_dispersion), trig = SIMD[DType.bool, 1](fill=True))
            )
        if trig:
            self.counter = (self.counter + 1) % overlaps_plus_2  # Cycle through 6 grains

        out = Float64(0.0)

        @parameter
        for i in range(overlaps_plus_2):
            start_frame: Int64 = 0
            
            if trig:
                self.pitch_ratio = pitch_ratio * linexp(random_float64(-pitch_dispersion, pitch_dispersion), -1.0, 1.0, 0.25, 4.0)
                if self.pitch_ratio <= 1.0:
                    start_frame = self.write_head
                else:
                    start_frame = (self.write_head - Int64((win_size * self.w[].sample_rate) * (self.pitch_ratio-1.0))) % len(self.buffer)
           
            out += self.grains[i].next[win_type=win_type](self.buffer, 0, i == self.counter, self.pitch_ratio, start_frame, win_size, 0.0, gain)
           
        return out