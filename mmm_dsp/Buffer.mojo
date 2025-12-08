from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from math import sin, log2, ceil, floor
from sys import simd_width_of
from mmm_src.MMMTraits import Buffable
from mmm_utils.Windows import build_sinc_table

alias dtype = DType.float64

struct Interp:
    alias none: Int = 0
    alias linear: Int = 1
    alias quad: Int = 2
    alias cubic: Int = 3
    alias lagrange: Int = 4
    alias sinc: Int = 5

trait Buffable(Copyable, Movable):
    # once traits have variables:
    # var prev_index: Float64

    fn get_num_frames(self) -> Float64: ...

    # [TODO] change the name of this fn
    fn get_item(self, chan_index: Int64, frame_index: Int64) -> Float64: ...

struct Buffer(Buffable):
    """Buffer for holding data (often audio data).

    There are two ways to initialize a Buffer (see the two `__init__` methods below):

    1. By providing a list of lists of Float64 samples, where each inner list represents a channel. You can also specify the sample rate of the buffer.

    2. As an "empty" buffer (filled with zeros) by specifying the number of channels and the number of samples per channel.
    """

    var num_frames: Int64  
    var buf_sample_rate: Float64  
    var prev_f_idx: Float64  # Previous floating-point index for sinc interpolation
    var num_chans: Int64  # Number of channels
    var data: List[List[Float64]]  # List of channels, each channel is a List of Float64 samples
    
    fn get_num_frames(self) -> Int64:
        return self.num_frames

    fn get_item(self, chan_index: Int64, frame_index: Int64) -> Float64:
        return self.data[chan_index][frame_index]

    @staticmethod
    fn zeros(samples: Int64 = 48000, num_chans: Int64 = 1, buf_sample_rate: Float64 = 48000.0):
        """
        Initialize a Buffer filled with zeros.

        Args:
            num_chans: Number of channels (default is 2 for stereo).
            samples: Number of samples per channel (default is 48000 for 1 second at 48kHz).
            buf_sample_rate: Sample rate of the buffer (default is 48000.0).
        """

        # Create a list of lists filled with zeros
        data = List[List[Float64]]()
        for _ in range(num_chans):
            channel_data = List[Float64]()
            for _ in range(samples):
                channel_data.append(0.0)  # Fill with zeros
            data.append(channel_data^)
        
        return Buffer(data, buf_sample_rate)
        
    @staticmethod
    def load(out self, filename: String, wavetables_per_channel: Int64 = 1):
        """
        Initialize a Buffer by loading data from a WAV file using SciPy and NumPy.

        Args:
            filename: Path to the WAV file to load.
        """
        # load the necessary Python modules

        scipy = Python.import_module("scipy")
        np = Python.import_module("numpy")
        py_data = scipy.io.wavfile.read(filename)  # Read the WAV file using SciPy

        buf_sample_rate = Float64(py_data[0])  # Sample rate is the first element of the tuple

        if wavetables_per_channel > 1:
            # If wavetables_per_channel is specified, calculate num_chans accordingly
            total_samples = py_data[1].shape[0]
            num_chans = wavetables_per_channel
            num_frames = total_samples / wavetables_per_channel
        else:
            num_frames = len(py_data[1])  # num_frames is the length of the data array
            if len(py_data[1].shape) == 1:
                # Mono file
                self.num_chans = 1
            else:
                # Multi-channel file
                num_chans = Int64(Float64(py_data[1].shape[1]))  # Number of num_chans is the second dimension of the data array

        data = py_data[1]  # Extract the actual sound data from the tuple
        # Convert to float64 if it's not already
        if data.dtype != np.float64:
            # If integer type, normalize to [-1.0, 1.0] range
            if np.issubdtype(data.dtype, np.integer):
                data = data.astype(np.float64) / np.iinfo(data.dtype).max
            else:
                data = data.astype(np.float64)
        
        # this returns a pointer to an interleaved array of floats
        data_ptr = data.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()

        # wavetables are stored in ordered channels, not interleaved
        if chans_per_channel > 1:
            for c in range(self.num_chans):
                channel_data = List[Float64]()
                for f in range(Int64(num_frames)):
                    channel_data.append(data_ptr[(c * Int64(num_frames)) + f])
                data.append(channel_data^)
        else:
            # normal multi-channel interleaved data
            for c in range(num_chans):
                channel_data = List[Float64]()
                for f in range(Int64(num_frames)):
                    channel_data.append(data_ptr[(f * num_chans) + c])
                data.append(channel_data^)

        return Buffer(data, buf_sample_rate)

    fn __init__(out self, lists: List[List[Float64]] = List[List[Float64]](), buf_sample_rate: Float64 = 48000.0):
        """
        Initialize a Buffer of data with channels.

        Args:
            lists: List of channels, each channel is a List of Float64 samples.
            buf_sample_rate: Sample rate of the buffer (default is 48000.0).
        """
        self.data = lists.copy()
        self.index = 0.0
        self.prev_f_idx = 0.0
        self.num_frames = len(self.data[0]) 
        self.buf_sample_rate = buf_sample_rate
        self.write_index = 0

        self.num_chans = len(self.data)  # Default number of channels (e.g., stereo)
        self.duration = self.num_frames / self.buf_sample_rate

    fn __repr__(self) -> String:
        return String("Buffer")

    # Reading Out Samples (No SIMD because Buffers are Lists of Lists of Float64s only)
    # =================================================================================

    @doc_private
    @always_inline
    fn read_index_quad(self, idx: Int64, idx1: Int64, idx2: Int64, frac: Float64, chan: Int64) -> Float64:
        """Read using provided indices with quadratic interpolation. No SIMD because Buffers are Lists of Lists of Float64s only."""
        
        y0 = self.data[chan][idx % self.num_frames]
        y1 = self.data[chan][idx1 % self.num_frames]
        y2 = self.data[chan][idx2 % self.num_frames]
        return quadratic_interp(y0, y1, y2, frac)

    @doc_private
    @always_inline
    fn read_index_linear(self, idx: Int64, idx1: Int64, frac: Float64, chan: Int64) -> Float64:
        """Read using provided indices with linear interpolation. No SIMD because Buffers are Lists of Lists of Float64s only."""
        
        y0 = self.data[chan][idx % self.num_frames]
        y1 = self.data[chan][idx1 % self.num_frames]
        return lerp(y0,y1,frac)

    @doc_private
    @always_inline
    fn read_index_none(self, index: Int64, chan: Int64) -> Float64:
        """Read using provided index with no interpolation. No SIMD because Buffers are Lists of Lists of Float64s only."""
        return self.data[chan][index % self.num_frames]

    @doc_private
    @always_inline
    fn read_index_sinc(self, f_idx: Float64, channel: Int64) -> Float64:
        """Read using provided phase with sinc interpolation. No SIMD because Buffers are Lists of Lists of Float64s only."""
        # Does this need to be phase or can it conform to the rest by being an index Float64?
        output = world_ptr[].sinc_interpolator.read_sinc(self, f_idx, prev_f_idx,channel)
        prev_f_idx = f_idx
        return output

    # Public:
    @always_inline
    fn read_phase[num_chans: Int = 1, interp: Int64 = Interp.quad](self, phase: Float64, start_chan: Int64 = 0) -> SIMD[DType.float64, num_chans]:
        """
        A read operation on the buffer that reads a multichannel buffer and returns a SIMD vector of size N. 
        It will start reading from the channel specified by start_chan and read N channels from there.

        Parameters:
            N: The number of channels to read (default is 1). The SIMD vector returned will have this size as well.

        Args:
            start_chan: The starting channel index to read from (0-based).
            phase: The phase position to read from, where 0.0 is the start of the buffer and 1.0 is the end.
            interp: The interpolation method to use (0 = linear, 1 = quadratic).
        """
        return self.read_index[num_chans, interp](phase * self.num_frames, start_chan)

    # Public:
    @always_inline
    fn read_index[num_chans: Int = 1, interp: Int64 = Interp.quad](self, f_idx: Float64, start_chan: Int64 = 0) -> SIMD[DType.float64, num_chans]:
        
        if self.num_frames == 0 or self.num_chans == 0:
            return SIMD[DType.float64, num_chans](0.0)  # Return zero if no frames or channels are available
        
        idx = Int64(f_idx)

        if idx < 0 or idx >= self.num_frames:
            return SIMD[DType.float64, num_chans](0.0)  # Out of bounds

        out = SIMD[DType.float64, num_chans](0.0)

        @parameter
        if interp == Interp.sinc:
            @parameter
            for i in range(num_chans):
                out[i] = self.read_phase_sinc(f_idx, start_chan + i)
            return out
        
        @parameter
        if interp == Interp.none:
            @parameter
            for i in range(num_chans):
                out[i] = self.read_index_none(idx, start_chan + i)
            return out

        # only need frac if interp != Interp.none
        frac = f_idx - Float64(idx)

        @parameter
        for i in range(num_chans):
            @parameter
            if interp == Interp.linear:
                out[i] = self.read_index_linear(idx, idx + 1, frac, start_chan + i)
            else interp == Interp.quad:
                out[i] = self.read_index_quad(idx, idx + 1, idx + 2, frac, start_chan + i)
        return out