from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld

alias dtype = DType.float64

struct Buffer(Representable, Movable, Copyable):
    """Buffer for holding data (often audio data).

    There are two ways to initialize a Buffer (see the two `__init__` methods below):

    1. By providing a list of lists of Float64 samples, where each inner list represents a channel. You can also specify the sample rate of the buffer.

    2. As an "empty" buffer (filled with zeros) by specifying the number of channels and the number of samples per channel.
    """

    var num_frames: Float64  
    var buf_sample_rate: Float64  
    var duration: Float64 
    var index: Float64  # Index for reading sound file data
    var num_chans: Int64  # Number of channels

    var data: List[List[Float64]]  # List of channels, each channel is a List of Float64 samples

    fn __init__(out self, lists: List[List[Float64]] = List[List[Float64]](), buf_sample_rate: Float64 = 48000.0):
        """
        Initialize a Buffer of data with channels.

        Args:
            lists: List of channels, each channel is a List of Float64 samples.
            buf_sample_rate: Sample rate of the buffer (default is 48000.0).
        """
        self.data = lists.copy()
        self.index = 0.0
        self.num_frames = len(self.data[0]) 
        self.buf_sample_rate = buf_sample_rate

        self.num_chans = len(self.data)  # Default number of channels (e.g., stereo)
        self.duration = self.num_frames / self.buf_sample_rate

    fn __init__(out self, num_chans: Int64 = 2, samples: Int64 = 48000, buf_sample_rate: Float64 = 48000.0):
        """
        Initialize a Buffer filled with zeros.

        Args:
            num_chans: Number of channels (default is 2 for stereo).
            samples: Number of samples per channel (default is 48000 for 1 second at 48kHz).
            buf_sample_rate: Sample rate of the buffer (default is 48000.0).
        """

        self.data = [[Float64(0.0) for _ in range(samples)] for _ in range(num_chans)]
        self.buf_sample_rate = buf_sample_rate
        self.index = 0.0
        self.duration = Float64(samples) / buf_sample_rate
        self.num_frames = Float64(samples)
        self.num_chans = num_chans

    fn __init__(out self, filename: String):
        """
        Initialize a Buffer by loading data from a WAV file using SciPy and NumPy.

        Args:
            filename: Path to the WAV file to load.
        """
        # load the necessary Python modules
        try:
            scipy = Python.import_module("scipy")
        except:
            print("Warning: Failed to import SciPy module")
            scipy = PythonObject(None)
        try:
            np = Python.import_module("numpy")
        except:
            print("Warning: Failed to import NumPy module")
            np = PythonObject(None)

        self.data = List[List[Float64]]()
        self.index = 0.0
        self.num_frames = 0.0 
        self.buf_sample_rate = 48000.0  
        self.duration = 0.0  
        self.num_chans = 0

        if filename != "":
            # Load the file if a filename is provided
            try:
                py_data = scipy.io.wavfile.read(filename)  # Read the WAV file using SciPy

                self.buf_sample_rate = Float64(py_data[0])  # Sample rate is the first element of the tuple

                self.num_frames = Float64(len(py_data[1]))  # num_frames is the length of the data array
                self.duration = self.num_frames / self.buf_sample_rate  # Calculate duration in seconds

                self.num_chans = Int64(Float64(py_data[1].shape[1]))  # Number of num_chans is the second dimension of the data array

                print("num_chans:", self.num_chans, "num_frames:", self.num_frames)  # Print the shape of the data array for debugging

                var data = py_data[1]  # Extract the actual sound data from the tuple
                # Convert to float64 if it's not already
                if data.dtype != np.float64:
                    # If integer type, normalize to [-1.0, 1.0] range
                    if np.issubdtype(data.dtype, np.integer):
                        data = data.astype(np.float64) / np.iinfo(data.dtype).max
                    else:
                        data = data.astype(np.float64)
                
                # this returns a pointer to an interleaved array of floats
                data_ptr = data.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()

                for c in range(self.num_chans):
                    channel_data = List[Float64]()
                    for f in range(Int64(self.num_frames)):
                        channel_data.append(data_ptr[(f * self.num_chans) + c])
                    self.data.append(channel_data^)

                print("Buffer initialized with file:", filename)  # Print the filename for debugging
            except:
                print("Error loading file:")
                self.num_frames = 0.0
                self.num_chans = 0
        else:
            self.num_frames = 0.0
            self.buf_sample_rate = 48000.0  # Default sample rate

    fn __repr__(self) -> String:
        return String("Buffer")

    @always_inline
    fn quadratic_interp_loc(self, idx: Int64, idx1: Int64, idx2: Int64, frac: Float64, chan: Int64) -> Float64:
        """Perform quadratic interpolation between three samples in the buffer."""
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames))
        var mod_idx1 = idx1 % (Int64(self.num_frames))
        var mod_idx2 = idx2 % (Int64(self.num_frames))

        # Get the 3 sample values
        var y0 = self.data[chan][mod_idx]
        var y1 = self.data[chan][mod_idx1]
        var y2 = self.data[chan][mod_idx2]

        return quadratic_interp(y0, y1, y2, frac)

    @always_inline
    fn linear_interp_loc(self, idx: Int64, idx1: Int64, frac: Float64, chan: Int64) -> Float64:
        """Perform linear interpolation between two samples in the buffer."""
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames))
        var mod_idx1 = idx1 % (Int64(self.num_frames))

        # Get the 2 sample values
        var y0 = self.data[chan][mod_idx]
        var y1 = self.data[chan][mod_idx1]
        return y0 + frac * (y1 - y0)

    fn read_sinc(mut self, chan: Int64, phase: Float64, last_phase: Float64) raises -> Float64:
        """Read a sample from the buffer using sinc interpolation.
        Sinc interpolation is a more accurate method of interpolation that can provide better audio quality, 
        especially for high-frequency content, which in this case would apply to very fast playback rates. 
        It uses a sinc function to interpolate between samples, which can help to reduce aliasing and 
        improve the fidelity of the output.
        This function is not yet implemented. """
        raise Error("Sinc interpolation is not implemented yet.")

    @always_inline
    fn read_index[N: Int = 1](mut self, start_chan: Int64, f_idx: Float64, interp: Int64 = 0) -> SIMD[DType.float64, N]:
        if self.num_frames == 0 or self.num_chans == 0:
            return SIMD[DType.float64, N](0.0)  # Return zero if no frames or channels are available
        
        var frac = f_idx - Float64(Int64(f_idx))

        var idx = Int64(f_idx)

        if idx < 0 or idx >= Int64(self.num_frames):
            return SIMD[DType.float64, N](0.0)  # Out of bounds

        var out = SIMD[DType.float64, N](0.0)
        for i in range(N):
            if interp == 0:
                out[i] = self.linear_interp_loc(idx, idx + 1, frac, start_chan + i)
            elif interp == 1:
                out[i] = self.quadratic_interp_loc(idx, (idx + 1), (idx + 2), frac, start_chan + i)
            else:
                out[i] = self.linear_interp_loc(idx, idx + 1, frac, start_chan + i)  # default is linear interpolation
        return out

    @always_inline
    fn read_phase[N: Int = 1](mut self, start_chan: Int64, phase: Float64, interp: Int64 = 0) -> SIMD[DType.float64, N]:
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

        var f_idx = phase * self.num_frames
        
        return self.read_index[N](start_chan, f_idx, interp)

    @always_inline
    fn write[N: Int](mut self, value: SIMD[DType.float64, N], index: Int64, start_channel: Int64 = 0):
        """Write a SIMD vector of values to the buffer at a specific index and channel.

        Args:
            value: The SIMD vector of values to write to the buffer.
            index: The index in the buffer to write to (0-based).
            start_channel: The starting channel index to write to (0-based).

        Returns:
            None
        """
        if index < 0 or index >= Int64(self.num_frames):
            return  # Out of bounds TODO: throw warning
        for i in range(len(value)):
            # only write into the buffer if the channel exists
            if start_channel + i < self.num_chans:
                self.data[start_channel + i][index] = value[i]
    
    fn write_next_index[N: Int](mut self, value: SIMD[DType.float64, N], start_channel: Int64 = 0):
        """The Buffer struct keeps an internal index that tracks where the next write should occur. 
        This method writes the given SIMD value to the buffer at the current index and then increments the index. 
        If the index exceeds the number of frames, it wraps around to the beginning of the buffer.
        
        Args:
            value: The SIMD vector of values to write to the buffer.
            start_channel: The starting channel index to write to (0-based).

        Returns:
            None
        """

        self.write[N=N](value, Int64(self.index), start_channel)
        self.index += 1.0
        if self.index >= self.num_frames:
            self.index = 0.0