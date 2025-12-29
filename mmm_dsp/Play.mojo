from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_dsp.Buffer import *
from mmm_src.MMMWorld import *
from .Osc import Dust, Impulse
from mmm_utils.functions import *
from .Pan import Pan2
from mmm_dsp.Filters import DCTrap
from mmm_utils.RisingBoolDetector import RisingBoolDetector
from time import time
from utils import Variant
from mmm_dsp.Recorder import Recorder

struct Play(Representable, Movable, Copyable):
    var impulse: Impulse  # Current phase of the buf
    var done: Bool
    var world: UnsafePointer[MMMWorld]  
    var rising_bool_detector: RisingBoolDetector
    var start_frame: Int64 
    var reset_phase_point: Float64
    var phase_offset: Float64  # Offset for the phase calculation

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        """ 
        
        Args:
            w: pointer to the MMMWorld instance.
        """

        self.world = world
        self.impulse = Impulse(self.world)
        self.done = True
        self.rising_bool_detector = RisingBoolDetector()

        self.start_frame = 0
        self.reset_phase_point = 0.0
        self.phase_offset = 0.0

    fn __repr__(self) -> String:
        return String("Play")

    # [TODO]: change "num_chans" to "num_outs"
    @always_inline
    fn next[num_chans: Int = 1, interp: Int = Interp.linear](mut self, buf: Buffer, rate: Float64 = 1, loop: Bool = True, trig: Bool = True, start_frame: Int64 = 0, var num_frames: Int64 = -1, start_chan: Int64 = 0) -> SIMD[DType.float64, num_chans]: 
        """Get the next sample from an audio buf (Buffer).

        Args:
            buf: The audio buf to read from (List[Float64]).
            rate: The playback rate. 1 is the normal speed of the buf.
            loop: Whether to loop the buf (default: True).
            trig: Trigger starts the synth at start_frame (default: 1.0).
            start_frame: The start frame for playback (default: 0) upon receiving a trigger.
            num_frames: The end frame for playback (default: -1 means to the end of the buf).
            start_chan: The start channel for multi-channel bufs (default: 0).

        Returns:
            The next sample(s) from the buf as a SIMD vector.
        """

        # self.world[].print("Play.mojo: next(): rate=", rate, " loop=", loop, " trig=", trig, " start_frame=", start_frame, " num_frames=", num_frames, " start_chan=", start_chan)

        # [TODO] I think we need to make sure these are within valid ranges:
        # * start_frame 
        # * start_chan
        # * N in correspondence with start_chan and buf channels
        # * num_frames in correspondence with start_frame and buf length

        out = SIMD[DType.float64, num_chans](0.0)

        # Determine Length of the Data
        # ============================
        if num_frames < 0 or num_frames + start_frame > buf.num_frames:
            num_frames = buf.num_frames - start_frame

        # Check for Trigger and if so, Update Values
        # ==========================================
        if self.rising_bool_detector.next(trig) and buf.num_frames_f64 > 0.0:
            self.done = False  # Reset done flag on trigger
            self.start_frame = start_frame  # Set start frame
            self.phase_offset = Float64(self.start_frame) / buf.num_frames_f64  
            self.reset_phase_point = Float64(num_frames) / buf.num_frames_f64  
        
        if self.done:
            return out  # Return zeros if done

        # Use Values to Calculate Frequency and Advance Phase
        # ===================================================
        freq = rate / buf.duration  # Calculate step size based on rate and sample rate
        # keep previous phase for sinc interp
        prev_phase = (self.impulse.phasor.phase + self.phase_offset) % 1.0
        # advance phase
        eor = self.impulse.next_bool(freq, trig = trig)

        # self.world[].print("Play.mojo: next(): phase=", self.impulse.phasor.phase, " freq=", freq, " prev_phase=", prev_phase, " data_len_f=", buf.num_frames_f64, " reset_phase_point=", self.reset_phase_point)

        if loop:
            # Wrap Phase
            if self.impulse.phasor.phase >= self.reset_phase_point:
                self.impulse.phasor.phase -= self.reset_phase_point
            return self.get_sample[num_chans,interp](buf, prev_phase, start_chan)
        else:
            # Not in Loop Mode
            if trig: eor = False
            phase = self.impulse.phasor.phase
            # [TODO] I feel like it might not be necessary to check *all* these?
            if phase >= 1.0 or phase < 0.0 or eor or phase >= self.reset_phase_point:
                self.done = True  # Set done flag if phase is out of bounds
                return 0.0
            else:
                return self.get_sample[num_chans,interp](buf, prev_phase, start_chan)

    @doc_private
    @always_inline
    fn get_sample[num_chans: Int, interp: Int](self, buf: Buffer, prev_phase: Float64, start_chan: Int64) -> SIMD[DType.float64, num_chans]:
        
        out = SIMD[DType.float64, num_chans](0.0)
        
        @parameter
        for out_chan in range(num_chans):
            out[out_chan] = ListInterpolator.read[interp=interp,bWrap=False](
                w=self.world,
                data=buf.data[(out_chan + start_chan) % len(buf.data)], # wrap around channels
                f_idx=((self.impulse.phasor.phase + self.phase_offset) % 1.0) * buf.num_frames_f64,
                prev_f_idx=prev_phase * buf.num_frames_f64
            )

        return out

struct Grain(Representable, Movable, Copyable):
    var world: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var start_frame: Int64
    var num_frames: Int64  
    var rate: Float64  
    var pan: Float64  
    var gain: Float64 
    var rising_bool_detector: RisingBoolDetector
    var panner: Pan2 
    var play_buf: Play
    var win_phase: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld], num_chans: Int64 = 2):
        self.world = world  

        self.start_frame = 0
        self.num_frames = 0
        self.rate = 1.0
        self.pan = 0.5 
        self.gain = 1.0
        self.rising_bool_detector = RisingBoolDetector()
        self.panner = Pan2(self.world)  
        self.play_buf = Play(self.world)
        self.win_phase = 0.0


    fn __repr__(self) -> String:
        return String("Grain")

    @always_inline
    fn next_pan[N: Int = 1, win_type: Int = WindowType.hann](mut self, mut buf: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        
        # self.world[].print("Grain.mojo: next_pan(): trig=", trig, " rate=", rate, " start_frame=", start_frame, " duration=", duration, " pan=", pan, " gain=", gain)

        var sample = self.next[N=N, win_type=win_type](buf, start_chan, trig, rate, start_frame, duration, pan, gain)

        # self.world[].print("Grain.mojo: next_pan(): sample=", sample)

        @parameter
        if N == 1:
            return self.panner.next(sample[0], self.pan)  # Return the output samples
        else:
            return SIMD[DType.float64, 2](sample[0], sample[1])  # Return the output samples

    # N can only be 1 (default) or 2
    # [TODO]: add interp parameter
    @always_inline
    fn next[N: Int = 1, win_type: Int = WindowType.hann](mut self, mut buf: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, N]:

        # self.world[].print("Grain.mojo: next(): trig=", trig, " rate=", rate, " start_frame=", start_frame, " duration=", duration, " pan=", pan, " gain=", gain)

        if self.rising_bool_detector.next(trig):
            self.start_frame = start_frame
            self.num_frames =  Int64(duration * buf.sample_rate * rate)  # Calculate end frame based on duration
            self.rate = rate
            self.gain = gain
            self.pan = pan

        sample = self.play_buf.next[num_chans=N,interp=Interp.linear](buf, self.rate, False, trig, self.start_frame, self.num_frames, start_chan) # Get samples from Play

        self.world[].print("Grain.mojo: next(): sample=", sample)

        # Get the current phase of the Play
        # [TODO]: I don't understand this if statement
        if self.play_buf.reset_phase_point > 0.0:
            self.win_phase = self.play_buf.impulse.phasor.phase / self.play_buf.reset_phase_point  
        else:
            self.win_phase = 0.0  # Use the phase

        win = self.world[].windows.at_phase[win_type](self.world, self.win_phase)

        # this only works with 1 or 2 channels, if you try to do more, it will just return 2 channels 
        # [TODO]: Either make this work with multichannels or document this limitation
        sample = sample * win * self.gain
        
        return sample

struct TGrains[max_grains: Int = 5](Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.
    """
    var grains: List[Grain]  
    var world: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector 
    var trig: Bool

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(max_grains):
            self.grains.append(Grain(self.world, 2))
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
    
    fn __repr__(self) -> String:
        return String("TGrains")

    @always_inline
    fn next[N: Int = 1, win_type: Int = WindowType.hann](mut self, mut buf: Buffer, buf_chan: Int = 0, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0, duration: Float64 = 0.1, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        """Generate the next set of grains.
        
        Args:.
            buf: Audio buf containing the source sound.
            trig: Trigger signal (>0 to start a new grain).
            rate: Playback rate of the grains (1.0 = normal speed).
            start_frame: Starting frame position in the buf.
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
            out += self.grains[i].next_pan[N=N,win_type=win_type](buf, buf_chan, b, rate, start_frame, duration, pan, gain)

        return out

struct PitchShift[overlaps: Int = 4](Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.

    Parameters:
        overlaps: Number of overlapping grains.

    Args:
        world: Pointer to the MMMWorld instance.
        buf_dur: Duration of the internal buf in seconds.


    """
    var grains: List[Grain]  
    var world: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector
    var trig: Bool
    var recorder: Recorder[1]
    var impulse: Dust
    var pitch_ratio: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld], buf_dur: Float64 = 1.0):
        """ 
            w: pointer to the MMMWorld instance.
            buf_dur: duration of the internal buf in seconds.
        """
        self.world = world  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(overlaps+2):
            self.grains.append(Grain(self.world)) 
            
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
        self.recorder = Recorder[1](self.world,Int64(buf_dur * w[].sample_rate), w[].sample_rate)
        self.impulse = Dust(self.world)
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
            buf: Audio buf containing the source sound.
            trig: Trigger signal (>0 to start a new grain).
            rate: Playback rate of the grains (1.0 = normal speed).
            start_frame: Starting frame position in the buf.
            duration: Duration of each grain in seconds.
            pan: Panning position from -1.0 (left) to 1.0 (right).
            gain: Amplitude scaling factor for the grains.

        Returns:
            List of output samples for all channels.
        """

        self.recorder.write_next(in_sig)
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
                    start_frame = self.recorder.write_head
                else:
                    start_frame = (self.recorder.write_head - Int64((win_size * self.world[].sample_rate) * (self.pitch_ratio-1.0))) % self.recorder.buf.num_frames
           
            out += self.grains[i].next[win_type=win_type](self.recorder.buf, 0, i == self.counter, self.pitch_ratio, start_frame, win_size, 0.0, gain)
           
        return out