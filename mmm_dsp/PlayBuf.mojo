from python import PythonObject
from python import Python
from memory import UnsafePointer
from .Buffer import *
from mmm_src.MMMWorld import MMMWorld
from .Osc import Impulse
from mmm_utils.functions import *
from .Env import Env
from .Pan2 import Pan2
from mmm_utils.Windows import hann_window


alias dtype = DType.float64

struct PlayBuf (Representable, Movable, Copyable):
    var impulse: Impulse  # Current phase of the buffer
    var num_chans: Int64  # Number of channels in the buffer
    var out_list: List[Float64]  # Output list for samples
    var sample_rate: Float64
    var done: Bool
    var world_ptr: UnsafePointer[MMMWorld]  
    var last_trig: Float64  
    var start_frame: Float64 
    var end_frame: Float64  
    var reset_point: Float64
    var phase_offset: Float64  # Offset for the phase calculation

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_chans: Int64 = 1):
        # Use the world instance directly instead of trying to copy it
        self.world_ptr = world_ptr
        # print("PlayBuf initialized with world sample rate:", self.world_ptr[0].sample_rate)  # Debug print
        self.impulse = Impulse(world_ptr)
        self.num_chans = num_chans
        self.sample_rate = self.world_ptr[0].sample_rate  # Sample rate from the MMMWorld instance
        self.out_list = List[Float64]()  # Initialize output list
        for _ in range(num_chans):
            self.out_list.append(0.0)  # Initialize output list with zeros
        self.done = True
        self.last_trig = 0.0  # Initialize last trigger time

        self.start_frame = 0.0  # Initialize start frame
        self.end_frame = 0.0  # Initialize end frame
        self.reset_point = 0.0  # Initialize reset point
        self.phase_offset = 0.0  # Initialize phase offset

    fn __repr__(self) -> String:
        return String("PlayBuf")


    fn next[T: Buffable](mut self: PlayBuf, mut buffer: T, rate: Float64, loop: Bool = True, trig: Float64 = 1.0, start_frame: Float64 = 0, end_frame: Float64 = -1) -> List[Float64]:
        """
        get the next sample from an audio buffer - can take both Buffer or InterleavedBuffer.

        Arguments:
            buffer: The audio buffer to read from (can be Buffer or InterleavedBuffer).
            rate: The playback rate (in Hz).
            loop: Whether to loop the buffer (default: True).
            trig: Trigger starts the synth at start_frame (default: 1.0).
            start_frame: The start frame for playback (default: 0) upon receiving a trigger.
            end_frame: The end frame for playback (default: -1).
        """

        num_frames = buffer.get_num_frames()
        duration = buffer.get_duration()

        # this should happen on the first call if trig > 0.0
        if trig > 0.0 and self.last_trig <= 0.0 and num_frames > 0:
            self.done = False  # Reset done flag on trigger
            self.start_frame = start_frame  # Set start frame
            if end_frame < 0 or end_frame > num_frames:
                self.end_frame = num_frames  # Set end frame to buffer length if not specified
            else:
                self.end_frame = end_frame  # Use specified end frame
            self.reset_point = abs(self.end_frame - self.start_frame) / num_frames  # Calculate reset point based on end_frame and start_frame
            self.phase_offset = self.start_frame / num_frames  # Calculate phase offset based on start_frame
            # print("PlayBuf start_frame:", self.start_frame, "end_frame:", self.end_frame, "reset_point:", self.reset_point, "phase_offset:", self.phase_offset)  # Debug print
        if self.done:
            self.last_trig = trig
            for i in range(self.num_chans):
                self.out_list[i] = 0.0
            return self.out_list  # Return zeros if phase is out of bounds
        else:
            var freq = rate / duration  # Calculate step size based on rate and sample rate

            if loop:
                _ = self.impulse.next(freq, trig = trig) 
                if self.impulse.phasor.phase >= self.reset_point:
                    self.impulse.phasor.phase -= self.reset_point
                for i in range(self.num_chans):
                    self.out_list[i] = buffer.next(i, self.impulse.phasor.phase + self.phase_offset, 1)  # Read the sample from the buffer at the current phase
            else:
                var eor = self.impulse.next(freq, trig = trig)
                eor -= trig
                if self.impulse.phasor.phase >= 1.0 or self.impulse.phasor.phase < 0.0 or eor > 0.0 or self.impulse.phasor.phase >= self.reset_point:
                    self.done = True  # Set done flag if phase is out of bounds
                    for i in range(self.num_chans):
                        self.out_list[i] = 0.0
                else:
                    for i in range(self.num_chans):
                        self.out_list[i] = buffer.next(i, self.impulse.phasor.phase + self.phase_offset, 1)  # Read the sample from the buffer at the current phase
            self.last_trig = trig  # Update last trigger time
            return self.out_list  


struct Grain(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var start_frame: Float64
    var end_frame: Float64  
    var duration: Float64  
    var rate: Float64  
    var pan: Float64  
    var gain: Float64 
    var last_trig: Float64  
    var panner: Pan2 
    var play_buf: PlayBuf
    var sample: Float64
    var win_phase: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], num_chans: Int64 = 2):
        self.world_ptr = world_ptr  

        self.start_frame = 0.0
        self.end_frame = 0.0
        self.duration = 0.0
        self.rate = 1.0
        self.pan = 0.5 
        self.gain = 1.0
        self.last_trig = 0.0 
        self.panner = Pan2()  
        self.play_buf = PlayBuf(world_ptr, 1)
        self.sample = 0.0
        self.win_phase = 0.0

    fn __repr__(self) -> String:
        return String("Grain")

    fn next[T: Buffable](mut self, mut buffer: T, trig: Float64 = 0.0, rate: Float64 = 1.0, start_frame: Float64 = 0.0, duration: Float64 = 0.0, pan: Float64 = 0.0, gain: Float64 = 1.0) -> List[Float64]:

        if trig > 0.0 and self.last_trig <= 0.0:
            self.start_frame = start_frame
            self.end_frame =  start_frame + duration * buffer.get_buf_sample_rate()  # Calculate end frame based on duration
            self.duration = (self.end_frame - self.start_frame) / self.world_ptr[0].sample_rate  # Calculate duration in seconds

            self.pan = pan 
            self.gain = gain
            self.rate = rate

            self.sample = self.play_buf.next(buffer, self.rate, False, trig, self.start_frame, self.end_frame)[0]  # Get samples from PlayBuf
        else:
            self.sample = self.play_buf.next(buffer, self.rate, False, 0.0, self.start_frame, self.end_frame)[0]  # Call next on PlayBuf with no trigger

        # Get the current phase of the PlayBuf
        if self.play_buf.reset_point > 0.0:
            self.win_phase = self.play_buf.impulse.phasor.phase / self.play_buf.reset_point  
        else:
            self.win_phase = 0.0  # Use the phase

        var win = self.world_ptr[0].hann_window.next(0, self.win_phase, 0)

        self.sample = self.sample * win * self.gain  # Apply the window to the sample
        output = self.panner.next(self.sample, self.pan)  # Apply panning and gain to the sample

        return output  # Return the output samples

struct TGrains(Representable, Movable, Copyable):
    """
    Triggered granular synthesis. Each trigger starts a new grain.
    """
    var grains: List[Grain]  
    var world_ptr: UnsafePointer[MMMWorld]
    var num_grains: Int64  
    var temp: List[Float64]  
    var counter: Int64  
    var last_trig: Float64  
    var trig: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], max_grains: Int64 = 5, chans: Int64 = 2):
        self.world_ptr = world_ptr  # Use the world instance directly
        self.num_grains = max_grains
        self.grains = List[Grain]()  # Initialize the list of grains
        for _ in range(max_grains):
            self.grains.append(Grain(world_ptr, 2))  
        self.temp = List[Float64]()
        for _ in range(chans):
            self.temp.append(0.0)  # Initialize temp list with zeros
        self.counter = 0  
        self.trig = 0.0  
        self.last_trig = 0.0  
    
    fn __repr__(self) -> String:
        return String("TGrains")

    fn next[T: Buffable](mut self, mut buffer: T, trig: Float64 = 0.0, rate: Float64 = 1.0, start_frame: Float64 = 0.0, duration: Float64 = 0.1, pan: Float64 = 0.0, gain: Float64 = 1.0) -> List[Float64]:
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

        if trig > 0.0 and self.last_trig <= 0.0:
            self.trig = trig  # Update trigger value
            self.counter += 1  # Increment the counter on trigger
            if self.counter >= self.num_grains:
                self.counter = 0  # Reset counter if it exceeds the number of grains
            var end_frame = start_frame + duration * buffer.get_buf_sample_rate()  # Calculate end frame based on duration
        else:
            self.trig = 0.0  # Reset trigger value if no trigger

        zero(self.temp)  # Reset temp list to zeros
        for i in range(self.num_grains):
            if i == self.counter and self.trig > 0.0:
                temp = self.grains[i].next(buffer, 1.0, rate, start_frame, duration, pan, gain)
                mix(self.temp, temp)
            else:
                temp = self.grains[i].next(buffer, 0.0, rate, start_frame, duration, pan, gain)
                mix(self.temp, temp)

        return self.temp  # Return the output samples