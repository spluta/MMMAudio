from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import Buffable

alias dtype = DType.float64

struct Buffer(Representable, Movable, Buffable, Copyable):
    """
    Has 2 possible constructors:

    1) Buffer(lists: List[List[Float64]], buf_sample_rate: Float64 = 48000.0).
       - lists: List of channels, each channel is a List of Float64 samples.
       - buf_sample_rate: Sample rate of the buffer (default is 48000.0).
    
    2) Buffer(num_chans: Int64 = 2, samples: Int64 = 48000, buf_sample_rate: Float64 = 48000.0).
       - num_chans: Number of channels (default is 2 for stereo).
       - samples: Number of samples per channel (default is 48000 for 1 second at 48kHz).
       - buf_sample_rate: Sample rate of the buffer (default is 48000.0).
       
    """

    var num_frames: Float64  
    var buf_sample_rate: Float64  
    var duration: Float64 
    var index: Float64  # Index for reading sound file data
    var num_chans: Int64  # Number of channels

    var data: List[List[Float64]]  # List of channels, each channel is a List of Float64 samples

    fn get_num_frames(self) -> Float64:
        """Return the number of frames in the buffer."""
        return self.num_frames
    fn get_duration(self) -> Float64:
        """Return the duration of the buffer in seconds."""
        return self.duration
    fn get_buf_sample_rate(self) -> Float64:
        """Return the sample rate of the buffer."""
        return self.buf_sample_rate

    fn __init__(out self, lists: List[List[Float64]] = List[List[Float64]](), buf_sample_rate: Float64 = 48000.0):
        self.data = lists.copy()
        self.index = 0.0
        self.num_frames = len(self.data[0]) 
        self.buf_sample_rate = buf_sample_rate

        self.num_chans = len(self.data)  # Default number of channels (e.g., stereo)
        self.duration = self.num_frames / self.buf_sample_rate

    fn __init__(out self, num_chans: Int64 = 2, samples: Int64 = 48000, buf_sample_rate: Float64 = 48000.0):
        self.data = [[Float64(0.0) for _ in range(samples)] for _ in range(num_chans)]
        self.buf_sample_rate = buf_sample_rate
        self.index = 0.0
        self.duration = Float64(samples) / buf_sample_rate
        self.num_frames = Float64(samples)
        self.num_chans = num_chans


    fn __repr__(self) -> String:
        return String("Buffer")

    fn quadratic_interp_loc(self, idx: Int64, idx1: Int64, idx2: Int64, frac: Float64, chan: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames))
        var mod_idx1 = idx1 % (Int64(self.num_frames))
        var mod_idx2 = idx2 % (Int64(self.num_frames))

        # Get the 3 sample values
        var y0 = self.data[chan][mod_idx]
        var y1 = self.data[chan][mod_idx1]
        var y2 = self.data[chan][mod_idx2]

        return quadratic_interp(y0, y1, y2, frac)

    fn linear_interp_loc(self, idx: Int64, idx1: Int64, frac: Float64, chan: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames))
        var mod_idx1 = idx1 % (Int64(self.num_frames))

        # Get the 2 sample values
        var y0 = self.data[chan][mod_idx]
        var y1 = self.data[chan][mod_idx1]
        return y0 + frac * (y1 - y0)

    fn read_sinc(mut self, chan: Int64, phase: Float64, last_phase: Float64) -> Float64:
        return 0.0

    fn read[N: Int = 1](mut self, start_chan: Int64, phase: Float64, interp: Int64 = 0) -> SIMD[DType.float64, N]:
        """
        A read operation on the buffer that reads a multichannel buffer and returns a SIMD vector of size N. It will start reading from the channel specified by start_chan and read N channels from there.

        read(start_chan, phase, interp=0)

        Parameters:
            N: The number of channels to read (default is 1). The SIMD vector returned will have this size as well.

        Args:
          start_chan: The starting channel index to read from (0-based).
          phase: The phase position to read from, where 0.0 is the start of the buffer and 1.0 is the end.
          interp: The interpolation method to use (0 = linear, 1 = quadratic).
        """

        if self.num_frames == 0 or self.num_chans == 0:
            return SIMD[DType.float64, N](0.0)  # Return zero if no frames or channels are available
        var f_idx = phase * self.num_frames
        var frac = f_idx - Float64(Int64(f_idx))

        var idx = Int64(f_idx)

        var out = SIMD[DType.float64, N](0.0)
        for i in range(N):
            if interp == 0:
                out[i] = self.linear_interp_loc(idx, idx + 1, frac, start_chan + i)
            elif interp == 1:
                out[i] = self.quadratic_interp_loc(idx, (idx + 1), (idx + 2), frac, start_chan + i)
            else:
                out[i] = self.linear_interp_loc(idx, idx + 1, frac, start_chan + i)  # default is linear interpolation

        return out

    # fn write(mut self, value: Float64, index: Int64, channel: Int64 = 0):
    #     if index < 0 or index >= Int64(self.num_frames):
    #         return  # Out of bounds
    #     self.data[channel][index] = value

    fn write[N: Int = 1](mut self, value: SIMD[DType.float64, N], index: Int64, start_channel: Int64 = 0):
        if index < 0 or index >= Int64(self.num_frames):
            return  # Out of bounds TODO: throw warning
        for i in range(len(value)):
            # only write into the buffer if the channel exists
            if start_channel + i < self.num_chans:
                self.data[start_channel + i][index] = value[i]