from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_dsp.Buffer import *
from mmm_src.MMMWorld import *
from .Osc import Dust, Phasor
from mmm_utils.functions import *
from .Pan import pan2, pan_az
from mmm_dsp.Filters import DCTrap
from mmm_utils.RisingBoolDetector import RisingBoolDetector
from time import time
from utils import Variant
from mmm_dsp.Recorder import Recorder


struct Play(Representable, Movable, Copyable):
    var impulse: Phasor  # Current phase of the buf
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
        self.impulse = Phasor(self.world)
        self.done = True
        self.rising_bool_detector = RisingBoolDetector()

        self.start_frame = 0
        self.reset_phase_point = 0.0
        self.phase_offset = 0.0

    fn __repr__(self) -> String:
        return String("Play")

    # [TODO]: change "num_chans" to "num_outs"
    @always_inline
    fn next[num_chans: Int = 1, interp: Int = Interp.linear, bWrap: Bool = False](mut self, buf: Buffer, rate: Float64 = 1, loop: Bool = True, trig: Bool = True, start_frame: Int64 = 0, var num_frames: Int64 = -1, start_chan: Int64 = 0) -> SIMD[DType.float64, num_chans]: 
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
        # this won't work if bWrap is True - but I think it is fine. it should just output 0 when it goes past the end of the buffer
        # if num_frames < 0 or num_frames + start_frame > buf.num_frames:
        #     num_frames = buf.num_frames - start_frame

        # Check for Trigger and if so, Update Values
        # ==========================================
        if self.rising_bool_detector.next(trig) and buf.num_frames_f64 > 0.0:
            self.done = False  # Reset done flag on trigger
            self.start_frame = start_frame  # Set start frame
            self.phase_offset = Float64(self.start_frame) / buf.num_frames_f64
            if num_frames < 0:
                self.reset_phase_point = 1.0
            else:
                self.reset_phase_point = Float64(num_frames) / buf.num_frames_f64  
        
        if self.done:
            return out  # Return zeros if done

        # Use Values to Calculate Frequency and Advance Phase
        # ===================================================
        freq = rate / buf.duration  # Calculate step size based on rate and sample rate
        # keep previous phase for sinc interp
        prev_phase = (self.impulse.phase + self.phase_offset) % 1.0
        # advance phase
        eor = self.impulse.next_bool(freq, trig = trig)

        if loop:
            # Wrap Phase
            if self.impulse.phase >= self.reset_phase_point:
                self.impulse.phase -= self.reset_phase_point
            return self.get_sample[num_chans,interp](buf, prev_phase, start_chan)
        else:
            # Not in Loop Mode
            if trig: eor = False
            phase = self.impulse.phase
            # [TODO] I feel like it might not be necessary to check *all* these?
            if phase >= 1.0 or phase < 0.0 or eor or phase >= self.reset_phase_point:
                self.done = True  # Set done flag if phase is out of bounds
                return 0.0
            else:
                return self.get_sample[num_chans,interp, bWrap](buf, prev_phase, start_chan)

    @doc_private
    @always_inline
    fn get_sample[num_chans: Int, interp: Int, bWrap: Bool = False](self, buf: Buffer, prev_phase: Float64, start_chan: Int64) -> SIMD[DType.float64, num_chans]:
        
        out = SIMD[DType.float64, num_chans](0.0)
        @parameter
        for out_chan in range(num_chans):
            out[out_chan] = ListInterpolator.read[interp=interp,bWrap=bWrap](
                world=self.world,
                data=buf.data[(out_chan + start_chan) % len(buf.data)], # wrap around channels
                f_idx=((self.impulse.phase + self.phase_offset) % 1.0) * buf.num_frames_f64,
                prev_f_idx=prev_phase * buf.num_frames_f64
            )
        return out

    @always_inline
    fn get_relative_phase(mut self) -> Float64:
        return self.impulse.phase / self.reset_phase_point  




struct Grain(Representable, Movable, Copyable):
    var world: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var start_frame: Int64
    var num_frames: Int64  
    var rate: Float64  
    var pan: Float64  
    var gain: Float64 
    var rising_bool_detector: RisingBoolDetector
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
        self.play_buf = Play(world)
        self.win_phase = 0.0


    fn __repr__(self) -> String:
        return String("Grain")

    @always_inline
    fn next_pan2[num_playback_chans: Int = 1, win_type: Int = 0, bWrap: Bool = False](mut self, mut buffer: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, loop: Bool = False, start_frame: Int64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        
        var sample = self.next[num_playback_chans=num_playback_chans, win_type=win_type, bWrap=bWrap](buffer, start_chan, trig, rate, loop, start_frame, duration, pan, gain)

        @parameter
        if num_playback_chans == 1:
            panned = pan2(sample[0], self.pan) #self.panner.next(sample[0], self.pan)  # Return the output samples
            return panned
        else:
            panned = pan2(SIMD[DType.float64, 2](sample[0], sample[1]), self.pan) #self.panner.next(sample[0], sample[1], self.pan)  # Return the output samples
            return panned  # Return the output samples

    @always_inline
    fn next_pan_az[num_simd_chans: Int = 4, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, loop: Bool = False, start_frame: Int64 = 0.0, duration: Float64 = 0.0, num_speakers: Int = 4, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, num_simd_chans]:
        
        var sample = self.next[num_playback_chans=1, win_type=win_type, bWrap=bWrap](buffer, start_chan, trig, rate, loop, start_frame, duration, pan, gain)

        panned = pan_az[num_simd_chans](sample[0], self.pan, num_speakers) #self.panner.next(sample[0], self.pan)  # Return the output samples
        return panned

    fn next[num_playback_chans: Int = 1, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, loop: Bool = False, start_frame: Int64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, num_playback_chans]:

        if self.rising_bool_detector.next(trig):
            self.start_frame = start_frame
            self.num_frames =  Int64(duration * buffer.sample_rate*rate)  # Calculate end frame based on duration
            self.rate = rate
            self.gain = gain
            self.pan = pan

            print(self.start_frame, self.num_frames, buffer.num_frames, bWrap)

            sample = self.play_buf.next[num_chans=num_playback_chans,interp=Interp.linear, bWrap=bWrap](buffer, self.rate, loop, trig, self.start_frame, self.num_frames, start_chan) # Get samples from PlayBuf
        else:
            sample = self.play_buf.next[num_chans=num_playback_chans,interp=Interp.linear, bWrap=bWrap](buffer, self.rate, loop, False, self.start_frame, self.num_frames, start_chan)  # Call next on PlayBuf with no trigger

        # Get the current phase of the PlayBuf
        if self.play_buf.reset_phase_point > 0.0:
            self.win_phase = self.play_buf.impulse.phase / self.play_buf.reset_phase_point  
        else:
            self.win_phase = 0.0  # Use the phase

        win = self.world[].windows.at_phase[win_type, Interp.linear](self.world, self.win_phase)

        # this only works with 1 or 2 channels, if you try to do more, it will just return 2 channels
        sample = sample * win * self.gain  # Apply the window to the sample
        
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
            self.grains.append(Grain(world, 2))  
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
    
    fn __repr__(self) -> String:
        return String("TGrains")

    @always_inline
    fn next[num_playback_chans: Int = 1, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: Buffer, buf_chan: Int = 0, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0, duration: Float64 = 0.1, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        """Generate the next set of grains. Uses pan2 to pan to 2 channels. Depending on num_playback_chans, will either pan a mono signal out 2 channels or a stereo signal out 2 channels.
        
        Parameters:
            num_playback_chans: Either 1 or 2, depending on whether you want to pan 1 channel of a buffer out 2 channels or 2 channels of the buffer with equal power panning.

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
            out += self.grains[i].next_pan2[num_playback_chans, WindowType.hann, bWrap=bWrap](buffer, buf_chan, b, rate, False, start_frame, duration, pan, gain)

        return out

    @always_inline
    fn next_pan_az[num_simd_chans: Int = 2, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: Buffer, buf_chan: Int = 0, trig: Bool = False, rate: Float64 = 1.0, start_frame: Int64 = 0, duration: Float64 = 0.1, num_speakers: Int = 2, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, num_simd_chans]:
        """Generate the next set of grains. Uses azimuth panning for N channel output.
        
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

        out = SIMD[DType.float64, num_simd_chans](0.0)
        @parameter
        for i in range(max_grains):
            b = i == self.counter and self.rising_bool_detector.state
            out += self.grains[i].next_pan_az[num_simd_chans, win_type, bWrap=bWrap](buffer, buf_chan, b, rate, False, start_frame, duration, num_speakers, pan, gain)

        return out


struct PitchShift[num_chans: Int = 1, overlaps: Int = 4, win_type: Int = WindowType.hann](Movable, Copyable):
    """
    An N channel granular pitchshifter. Each channel is processed in parrallel, thus each of the grains.

    Parameters:
        num_chans: Number of input/output channels.
        overlaps: Number of overlapping grains (default is 4).
        win_type: Type of window to apply to each grain (default is Hann window (WinType.hann)).

    Args:
        world: Pointer to the MMMWorld instance.
        buf_dur: Duration of the internal buffer in seconds.


    """
    var grains: List[Grain]  
    var world: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector
    var trig: Bool
    var recorder: Recorder[num_chans]
    var impulse: Dust
    var pitch_ratio: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld], buf_dur: Float64 = 1.0):
        """ 
            world: pointer to the MMMWorld instance.
            buf_dur: duration of the internal buffer in seconds.
        """
        self.world = world  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(overlaps+2):
            self.grains.append(Grain(world)) 
            
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
        self.recorder = Recorder[num_chans](world, Int(buf_dur * world[].sample_rate), world[].sample_rate)
        self.impulse = Dust(world)
        self.pitch_ratio = 1.0
    
    fn __repr__(self) -> String:
        return String("TGrains")

    # PitchShift.ar(in: 0.0, windowSize: 0.2, pitchRatio: 1.0, pitchDispersion: 0.0, timeDispersion: 0.0, mul: 1.0, add: 0.0)

    @always_inline
    fn next(mut self, in_sig: SIMD[DType.float64, num_chans], grain_dur: Float64 = 0.2, pitch_ratio: Float64 = 1.0, pitch_dispersion: Float64 = 0.0, time_dispersion: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, num_chans]:
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

        self.recorder.write_next(in_sig)  # Write the input signal into the buffer
        alias overlaps_plus_2 = overlaps + 2

        trig_rate = overlaps / grain_dur
        trig = self.rising_bool_detector.next(
            self.impulse.next_bool(trig_rate*(1-time_dispersion), trig_rate*(1+time_dispersion), trig = SIMD[DType.bool, 1](fill=True))
            )
        if trig:
            self.counter = (self.counter + 1) % overlaps_plus_2  # Cycle through 6 grains

        out = SIMD[DType.float64, num_chans](0.0)

        @parameter
        for i in range(overlaps_plus_2):
            start_frame = 0
            
            if trig:
                self.pitch_ratio = pitch_ratio * linexp(random_float64(-pitch_dispersion, pitch_dispersion), -1.0, 1.0, 0.25, 4.0)
                if self.pitch_ratio <= 1.0:
                    start_frame = Int(self.recorder.write_head)
                else:
                    start_frame = Int(Float64(self.recorder.write_head) - ((grain_dur * self.world[].sample_rate) * (self.pitch_ratio-1.0))) % Int(self.recorder.buf.num_frames)
                
            if i == self.counter:
                out += self.grains[i].next[num_chans, win_type=win_type, bWrap=True](self.recorder.buf, 0, True, self.pitch_ratio, False, start_frame, grain_dur, 0.0, gain)
            else:
                out += self.grains[i].next[num_chans, win_type=win_type, bWrap=True](self.recorder.buf, 0, False, self.pitch_ratio, False, start_frame, grain_dur, 0.0, gain)

        return out