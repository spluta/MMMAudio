from python import PythonObject
from python import Python
from memory import UnsafePointer
from .Buffer import *
from mmm_src.MMMWorld import MMMWorld
from .Osc import Dust, Impulse
from mmm_utils.functions import *
from .Pan import Pan2
from mmm_utils.Windows import hann_window
from mmm_dsp.Filters import DCTrap
from mmm_utils.RisingBoolDetector import RisingBoolDetector
from time import time

alias dtype = DType.float64

struct PlayBuf(Representable, Movable, Copyable):
    var impulse: Impulse  # Current phase of the buffer
    var sample_rate: Float64
    var done: Bool
    var world_ptr: UnsafePointer[MMMWorld]  
    var rising_bool_detector: RisingBoolDetector
    var start_frame: Float64 
    var end_frame: Float64  
    var reset_phase_point: Float64
    var phase_offset: Float64  # Offset for the phase calculation

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """ world_ptr: pointer to the MMMWorld instance.
            num_chans: number of channels in the buffer.

        """
        # Use the world instance directly instead of trying to copy it
        self.world_ptr = world_ptr
        # print("PlayBuf initialized with world sample rate:", self.world_ptr[0].sample_rate)  # Debug print
        self.impulse = Impulse(world_ptr)
        # self.num_chans = num_chans
        self.sample_rate = self.world_ptr[0].sample_rate  # Sample rate from the MMMWorld instance
        self.done = True
        self.rising_bool_detector = RisingBoolDetector()

        self.start_frame = 0.0  # Initialize start frame
        self.end_frame = 0.0  # Initialize end frame
        self.reset_phase_point = 0.0  # Initialize reset point
        self.phase_offset = 0.0  # Initialize phase offset

    fn __repr__(self) -> String:
        return String("PlayBuf")

    @always_inline
    fn next[N: Int=1](mut self: PlayBuf, mut buffer: Buffer, start_chan: Int,rate: Float64, loop: Bool = True, trig: Bool = True, start_frame: Float64 = 0, num_frames: Float64 = -1) -> SIMD[DType.float64, N]: 
        """
        get the next sample from an audio buffer (Buffer)

        Arguments:
            buffer: The audio buffer to read from (Buffer struct).
            rate: The playback rate. 1 is the normal speed of the buffer.
            loop: Whether to loop the buffer (default: True).
            trig: Trigger starts the synth at start_frame (default: 1.0).
            start_frame: The start frame for playback (default: 0) upon receiving a trigger.
            num_frames: The end frame for playback (default: -1).
        """

        duration = buffer.get_duration()
        if num_frames < 0:
            num_frames2 = buffer.num_frames
        else:
            num_frames2 = num_frames

        out = SIMD[DType.float64, N](0.0)

        # this should happen on the first call if trig > 0.0
        # or when any trig happens
        if self.rising_bool_detector.next(trig) and buffer.num_frames > 0:
            self.done = False  # Reset done flag on trigger
            self.start_frame = start_frame  # Set start frame
            # if end_frame < 0 or end_frame > num_frames:
            #     self.end_frame = num_frames  # Set end frame to buffer length if not specified
            # else:
            self.end_frame = start_frame + num_frames2  # Use specified end frame
            self.reset_phase_point = num_frames2 / buffer.num_frames  # Calculate reset point based on end_frame and start_frame
            self.phase_offset = self.start_frame / buffer.num_frames  # Calculate phase offset based on start_frame  
        if self.done:
            return out  # Return zeros if done
        else:
            var freq = rate / duration  # Calculate step size based on rate and sample rate

            if loop:
                _ = self.impulse.next(freq, trig = trig) 
                if self.impulse.phasor.phase >= self.reset_phase_point:
                    self.impulse.phasor.phase -= self.reset_phase_point
                # for i in range(N):
                out = buffer.read[N](start_chan, (self.impulse.phasor.phase + self.phase_offset) % 1.0, 1)  # Read the sample from the buffer at the current phase
            else:
                var eor = self.impulse.next_bool(freq, trig = trig)
                if trig: eor = False
                phase = self.impulse.phasor.phase
                if phase >= 1.0 or phase < 0.0 or eor or phase >= self.reset_phase_point:
                    self.done = True  # Set done flag if phase is out of bounds
                    return out
                else:
                    out = buffer.read[N](start_chan, (self.impulse.phasor.phase + self.phase_offset) % 1.0, 1)  # Read the sample from the buffer at the current phase
            
            return out

    
    fn get_win_phase(mut self: PlayBuf) -> Float64:
        if self.reset_phase_point > 0.0:
            return self.impulse.get_phase() / self.reset_phase_point  
        else:
            return 0.0  # Use the phase


struct Grain(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var start_frame: Float64
    var num_frames: Float64  
    var rate: Float64  
    var pan: Float64  
    var gain: Float64 
    var rising_bool_detector: RisingBoolDetector
    var panner: Pan2 
    var play_buf: PlayBuf
    var win_phase: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_chans: Int64 = 2):
        self.world_ptr = world_ptr  

        self.start_frame = 0.0
        self.num_frames = 0.0
        self.rate = 1.0
        self.pan = 0.5 
        self.gain = 1.0
        self.rising_bool_detector = RisingBoolDetector()
        self.panner = Pan2(world_ptr)  
        self.play_buf = PlayBuf(world_ptr)
        self.win_phase = 0.0


    fn __repr__(self) -> String:
        return String("Grain")

    @always_inline
    fn next_pan[N: Int = 1, win_num: Int = 0](mut self, mut buffer: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, start_frame: Float64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        
        var sample = self.next[N=N, win_num=win_num](buffer, start_chan, trig, rate, start_frame, duration, pan, gain)

        @parameter
        if N == 1:
            return self.panner.next(sample[0], self.pan)  # Return the output samples
        else:
            return SIMD[DType.float64, 2](sample[0], sample[1])  # Return the output samples

    # N can only be 1 (default) or 2
    fn next[N: Int = 1, win_num: Int = 0](mut self, mut buffer: Buffer, start_chan: Int, trig: Bool = False, rate: Float64 = 1.0, start_frame: Float64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, N]:

        if self.rising_bool_detector.next(trig):
            self.start_frame = start_frame
            self.num_frames =  (duration * buffer.get_buf_sample_rate()*rate)  # Calculate end frame based on duration
            self.rate = rate
            self.gain = gain
            self.pan = pan

            sample = self.play_buf.next[N=N](buffer, start_chan, self.rate, False, trig, self.start_frame, self.num_frames) # Get samples from PlayBuf
        else:
            sample = self.play_buf.next[N=N](buffer, start_chan, self.rate, False, False, self.start_frame, self.num_frames)  # Call next on PlayBuf with no trigger

        # Get the current phase of the PlayBuf
        if self.play_buf.reset_phase_point > 0.0:
            self.win_phase = self.play_buf.impulse.phasor.phase / self.play_buf.reset_phase_point  
        else:
            self.win_phase = 0.0  # Use the phase

        @parameter
        if win_num == 0:
            win = self.world_ptr[0].hann_window.read(0, self.win_phase, 0)
        # Future window types can be added here with elif statements
        else:
            win = 1-2*abs(self.win_phase - 0.5) # hackey triangular window


        # this only works with 1 or 2 channels, if you try to do more, it will just return 2 channels
        sample = sample * win * self.gain  # Apply the window to the sample
        
        return sample

struct TGrains[max_grains: Int = 5](Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.
    """
    var grains: List[Grain]  
    var world_ptr: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector 
    var trig: Bool

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(max_grains):
            self.grains.append(Grain(world_ptr, 2))  
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
    
    fn __repr__(self) -> String:
        return String("TGrains")

    @always_inline
    fn next[N: Int = 1](mut self, mut buffer: Buffer, buf_chan: Int = 0, trig: Bool = False, rate: Float64 = 1.0, start_frame: Float64 = 0.0, duration: Float64 = 0.1, pan: Float64 = 0.0, gain: Float64 = 1.0) -> SIMD[DType.float64, 2]:
        """Generate the next set of grains.
        
        Arguments:.
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
            out += self.grains[i].next_pan[N=N](buffer, buf_chan, b, rate, start_frame, duration, pan, gain)

        return out

struct PitchShift[overlaps: Int = 4](Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.

    Parameters:
        N: Number of channels (default is 1).

    Args:
        world_ptr: Pointer to the MMMWorld instance.
        buf_dur: Duration of the internal buffer in seconds.


    """
    var grains: List[Grain]  
    var world_ptr: UnsafePointer[MMMWorld]
    var counter: Int 
    var rising_bool_detector: RisingBoolDetector
    var trig: Bool
    var buffer: Buffer
    var impulse: Dust
    var pitch_ratio: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], buf_dur: Float64 = 1.0):
        """ 
            world_ptr: pointer to the MMMWorld instance.
            buf_dur: duration of the internal buffer in seconds.
        """
        self.world_ptr = world_ptr  # Use the world instance directly
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(overlaps+2):
            self.grains.append(Grain(world_ptr)) 
            
        self.counter = 0  
        self.trig = False  
        self.rising_bool_detector = RisingBoolDetector()
        self.buffer = Buffer(1, Int(buf_dur * world_ptr[0].sample_rate), world_ptr[0].sample_rate)  # Empty buffer to be set later
        self.impulse = Dust(world_ptr)
        self.pitch_ratio = 1.0
    
    fn __repr__(self) -> String:
        return String("TGrains")

    # PitchShift.ar(in: 0.0, windowSize: 0.2, pitchRatio: 1.0, pitchDispersion: 0.0, timeDispersion: 0.0, mul: 1.0, add: 0.0)

    @always_inline
    fn next(mut self, in_sig: Float64, win_size: Float64 = 0.2, pitch_ratio: Float64 = 1.0, pitch_dispersion: Float64 = 0.0, time_dispersion: Float64 = 0.0, gain: Float64 = 1.0) -> Float64:
        """Generate the next set of grains.
        
        Parameters:
            out_chans: Number of output channels.

        Arguments:.
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

        self.buffer.write_next_index(in_sig)  # Write the input signal into the buffer
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
            start_frame = 0
            
            if trig:
                self.pitch_ratio = pitch_ratio * linexp(random_float64(-pitch_dispersion, pitch_dispersion), -1.0, 1.0, 0.25, 4.0)
                if self.pitch_ratio <= 1.0:
                    start_frame = Int(self.buffer.index)
                else:
                    start_frame = Int(self.buffer.index - ((win_size * self.world_ptr[0].sample_rate) * (self.pitch_ratio-1))) % Int(self.buffer.get_num_frames())
            if i == self.counter:
                out += self.grains[i].next[win_num=1](self.buffer, 0, True, self.pitch_ratio, start_frame, win_size, 0.0, gain)
            else:
                out += self.grains[i].next[win_num=1](self.buffer, 0, False, self.pitch_ratio, start_frame, win_size, 0.0, gain)

        return out