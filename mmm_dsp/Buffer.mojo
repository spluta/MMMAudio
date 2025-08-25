from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import Buffable

alias dtype = DType.float64

struct InterleavedBuffer(Representable, Movable, Buffable, Copyable):
    var num_frames: Float64  
    var buf_sample_rate: Float64  
    var sys_sample_rate: Float64 
    var step: Float64
    var duration: Float64 
    var py_data: PythonObject  # Placeholder for Python data object
    var scipy: PythonObject # Placeholder for SciPy or similar library
    var np: PythonObject  # Placeholder for NumPy or similar library
    var index: Float64  # Index for reading sound file data
    var num_chans: Int64  # Number of channels

    var data: UnsafePointer[SIMD[dtype, 1]]  # Pointer to the sound data, could be numpy array or Mojo List/InlineArray

    fn get_num_frames(self) -> Float64:
        """Return the number of frames in the buffer."""
        return self.num_frames
    fn get_duration(self) -> Float64:
        """Return the duration of the buffer in seconds."""
        return self.duration
    fn get_buf_sample_rate(self) -> Float64:
        """Return the sample rate of the buffer."""
        return self.buf_sample_rate

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], filename: String = ""):
        # load the necessary Python modules
        try:
            self.scipy = Python.import_module("scipy")
        except:
            print("Warning: Failed to import SciPy module")
            self.scipy = PythonObject(None)
        try:
            self.np = Python.import_module("numpy")
        except:
            print("Warning: Failed to import NumPy module")
            self.np = PythonObject(None)

        self.data = UnsafePointer[SIMD[dtype, 1]]()
        self.py_data = PythonObject(None)  # Placeholder for Python data object
        self.index = 0.0
        self.num_frames = 0.0  # Initialize num_frames
        self.buf_sample_rate = 48000.0  # Default sample rate if loading fails

        self.sys_sample_rate = world_ptr[0].sample_rate  # system sample rate
        self.step = 1 / self.sys_sample_rate
        self.num_chans = 0  # Default number of channels (e.g., stereo)
        self.duration = 0.0  # Initialize duration
        self.num_frames = 0.0  # Initialize number of frames

        if filename != "":
            # Load the file if a filename is provided
            try:
                self.load_file(filename)
                print("Buffer initialized with file:", filename)  # Print the filename for debugging
            except:
                print("Error loading file:")
                self.num_frames = 0.0
                self.num_chans = 0
        else:
            self.num_frames = 0.0
            self.buf_sample_rate = 48000.0  # Default sample rate


    fn load_file(mut self, filename: String) raises -> PythonObject:
        # using SciPy to read the WAV file
        # loading this into a struct variable so that it hopefully will not be garbage collected
        self.py_data = self.scipy.io.wavfile.read(filename)  # Read the WAV file using SciPy

        self.buf_sample_rate = Float64(self.py_data[0])  # Sample rate is the first element of the tuple

        self.num_frames = Float64(len(self.py_data[1]))  # num_frames is the length of the data array
        self.duration = self.num_frames / self.buf_sample_rate  # Calculate duration in seconds

        self.num_chans = Int64(Float64(self.py_data[1].shape[1]))  # Number of num_chans is the second dimension of the data array
        
        print("num_chans:", self.num_chans, "num_frames:", self.num_frames)  # Print the shape of the data array for debugging

        self.step = (self.buf_sample_rate / self.sys_sample_rate) / self.num_frames  # Update step based on system sample rate

        var data = self.py_data[1]  # Extract the actual sound data from the tuple
        # Convert to float64 if it's not already
        if data.dtype != self.np.float64:
            # If integer type, normalize to [-1.0, 1.0] range
            if self.np.issubdtype(data.dtype, self.np.integer):
                data = data.astype(self.np.float64) / self.np.iinfo(data.dtype).max
            else:
                data = data.astype(self.np.float64)
        
        # this returns a pointer to an interleaved array of floats
        self.data = data.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()
        # print(len(self.data), "samples loaded from file:", filename)  # Print the number of samples loaded for debugging

        return None

    fn __repr__(self) -> String:
        return String("InterleavedBuffer")

    fn quadratic_interp_loc(self, idx: Int64, idx1: Int64, idx2: Int64, frac: Float64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames) * self.num_chans)
        var mod_idx1 = idx1 % (Int64(self.num_frames) * self.num_chans)
        var mod_idx2 = idx2 % (Int64(self.num_frames) * self.num_chans)

        # Get the 3 sample values
        var y0 = self.data[mod_idx]
        var y1 = self.data[mod_idx1]
        var y2 = self.data[mod_idx2]

        return quadratic_interpolation(y0, y1, y2, frac)

    fn linear_interp_loc(self, idx: Int64, idx1: Int64, frac: Float64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames) * self.num_chans)
        var mod_idx1 = idx1 % (Int64(self.num_frames) * self.num_chans)

        # Get the 2 sample values
        var y0 = self.data[mod_idx]
        var y1 = self.data[mod_idx1]
        return y0 + frac * (y1 - y0)  # Linear interpolation between

    fn next_sinc(mut self, chan: Int64, phase: Float64, last_phase: Float64) -> Float64:
        return 0.0

    fn next(mut self, chan: Int64, phase: Float64, interp: Int64 = 0) -> Float64:
        if self.num_frames == 0 or self.num_chans == 0:
            return 0.0  # Return zero if no frames or channels are available
        var f_idx = phase * self.num_frames
        var frac = f_idx - Float64(Int64(f_idx))

        var idx = Int64(f_idx) * self.num_chans + chan

        var out = 0.0  

        if interp == 0:
            out = self.linear_interp_loc(idx, idx + self.num_chans, frac)
        elif interp == 1:
            out = self.quadratic_interp_loc(idx, (idx + self.num_chans), (idx + (2 * self.num_chans)), frac)
        return out

struct Buffer(Representable, Movable, Buffable, Copyable):
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

    fn __init__(out self, lists: List[List[Float64]] = List[List[Float64]](), sample_rate: Float64 = 48000.0):
        print(len(lists), len(lists[0]) if len(lists) > 0 else 0)
        self.data = lists
        print(len(self.data), len(self.data[0]) if len(self.data) > 0 else 0)
        self.index = 0.0
        self.num_frames = len(self.data[0]) 
        self.buf_sample_rate = sample_rate

        self.num_chans = len(self.data)  # Default number of channels (e.g., stereo)
        self.duration = self.num_frames / self.buf_sample_rate


    fn __repr__(self) -> String:
        return String("Buffer")

    fn quadratic_interp_loc(self, idx: Int64, idx1: Int64, idx2: Int64, frac: Float64, chan: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames))
        var mod_idx1 = idx1 % (Int64(self.num_frames))
        var mod_idx2 = idx2 % (Int64(self.num_frames))

        # Get the 3 sample values
        var y0 = self.data[mod_idx][chan]
        var y1 = self.data[mod_idx1][chan]
        var y2 = self.data[mod_idx2][chan]

        return quadratic_interpolation(y0, y1, y2, frac)

    fn linear_interp_loc(self, idx: Int64, idx1: Int64, frac: Float64, chan: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = idx % (Int64(self.num_frames))
        var mod_idx1 = idx1 % (Int64(self.num_frames))

        # Get the 2 sample values
        var y0 = self.data[chan][mod_idx]
        var y1 = self.data[chan][mod_idx1]
        return y0 + frac * (y1 - y0)

    fn next_sinc(mut self, chan: Int64, phase: Float64, last_phase: Float64) -> Float64:
        return 0.0

    fn next(mut self, chan: Int64, phase: Float64, interp: Int64 = 0) -> Float64:

        if self.num_frames == 0 or self.num_chans == 0:
            return 0.0  # Return zero if no frames or channels are available
        var f_idx = phase * self.num_frames
        var frac = f_idx - Float64(Int64(f_idx))

        var idx = Int64(f_idx)

        if interp == 0:
            return self.linear_interp_loc(idx, idx + 1, frac, chan)
        elif interp == 1:
            return self.quadratic_interp_loc(idx, (idx + 1), (idx + 2), frac, chan)
        else:
            return self.linear_interp_loc(idx, idx + 1, frac, chan)  # default is linear interpolation