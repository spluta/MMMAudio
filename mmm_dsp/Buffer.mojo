from python import PythonObject
from python import Python
from mmm_utils.functions import *
from mmm_src.MMMWorld import *
from math import sin, log2, ceil, floor
from sys import simd_width_of
from mmm_utils.functions import linear_interp, quadratic_interp

struct Buffer(Movable, Copyable):
    var data: List[List[Float64]]
    var num_chans: Int64
    var num_frames: Int64
    var num_frames_f64: Float64
    var sample_rate: Float64

    def __init__(out self, data: List[List[Float64]], sample_rate: Float64):

        if len(data) > 1:
            for chan in range(1,len(data)):
                if len(data[chan]) != len(data[0]):
                    raise Error("Buffer::__init__ All channels must have the same number of frames")

        self.data = data.copy()
        self.sample_rate = sample_rate

        self.num_chans = len(data)
        self.num_frames = len(data[0]) if self.num_chans > 0 else 0
        self.num_frames_f64 = Float64(self.num_frames)

    @staticmethod
    def zeros(num_frames: Int64, num_chans: Int64 = 1, sample_rate: Float64 = 48000.0) -> Buffer:
        """Initialize a Buffer with zeros.

        Args:
            num_frames: Number of frames in the buffer.
            num_chans: Number of channels in the buffer.
            sample_rate: Sample rate of the buffer.
        """

        var data = List[List[Float64]]()
        for __repr__ in range(num_chans):
            channel_data = List[Float64]()
            for _ in range(num_frames):
                channel_data.append(0.0)
            data.append(channel_data^)

        return Buffer(data, sample_rate)

    @staticmethod
    def load(filename: String, num_wavetables: Int64 = 1) -> Buffer:
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

        self_data = List[List[Float64]]()

        if filename != "":
            # Load the file if a filename is provided
            try:
                py_data = scipy.io.wavfile.read(filename)  # Read the WAV file using SciPy

                print(py_data)  # Print the loaded data for debugging

                self_sample_rate = Float64(py_data[0])  # Sample rate is the first element of the tuple

                if num_wavetables > 1:
                    # If num_wavetables is specified, calculate num_chans accordingly
                    total_samples = py_data[1].shape[0]
                    self_num_chans = num_wavetables
                    self_num_frames = Int64(Float64(total_samples) / Float64(num_wavetables))
                else:
                    self_num_frames = Int64(len(py_data[1]))  # num_frames is the length of the data array
                    if len(py_data[1].shape) == 1:
                        # Mono file
                        self_num_chans = 1
                    else:
                        # Multi-channel file
                        self_num_chans = Int64(Float64(py_data[1].shape[1]))  # Number of num_chans is the second dimension of the data array

                self_num_frames_f64 = Float64(self_num_frames)
                print("num_chans:", self_num_chans, "num_frames:", self_num_frames)  # Print the shape of the data array for debugging

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

                # wavetables are stored in ordered channels, not interleaved
                if num_wavetables > 1:
                    for c in range(self_num_chans):
                        channel_data = List[Float64]()
                        for f in range(Int64(self_num_frames)):
                            channel_data.append(data_ptr[(c * Int64(self_num_frames)) + f])
                        self_data.append(channel_data^)
                else:
                    # normal multi-channel interleaved data
                    for c in range(self_num_chans):
                        channel_data = List[Float64]()
                        for f in range(Int64(self_num_frames)):
                            channel_data.append(data_ptr[(f * self_num_chans) + c])
                        self_data.append(channel_data^)

                print("Buffer initialized with file:", filename)  # Print the filename for debugging
                return Buffer(self_data, self_sample_rate)
            except err:
                raise Error("Buffer::__init__ Error loading file: ", filename, " Error: ", err)
        else:
            raise Error("Buffer::__init__ No filename provided")

struct ListInterpolator(Movable, Copyable):

    @always_inline
    @staticmethod
    fn idx_in_range(data: List[Float64], idx: Int64) -> Bool:
        return idx >= 0 and idx < len(data)

    # Once structs are allowed to have static variables, the since table will be stored in here so that 
    # a reference to the MMMWorld is not needed for every read call.
    @always_inline
    @staticmethod
    fn read[interp: Int = Interp.none, bWrap: Bool = True, mask: Int = 0](w: UnsafePointer[MMMWorld], data: List[Float64], f_idx: Float64, prev_f_idx: Float64 = 0.0) -> Float64:
        """Read a value from a List[Float64] using provided index and interpolation method."""
        
        @parameter
        if interp == Interp.none:
            return ListInterpolator.read_none[bWrap,mask](data, f_idx)
        elif interp == Interp.linear:
            return ListInterpolator.read_linear[bWrap,mask](data, f_idx)
        elif interp == Interp.quad:
            return ListInterpolator.read_quad[bWrap,mask](data, f_idx)
        elif interp == Interp.sinc:
            return ListInterpolator.read_sinc[bWrap,mask](w,data, f_idx, prev_f_idx)
        else:
            print("ListInterpolator fn read:: Unsupported interpolation method")
            return 0.0

    @always_inline
    @staticmethod
    fn read_none[bWrap: Bool = True, mask: Int = 0](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a List[Float64] using provided index with no interpolation."""

        idx = Int64(f_idx)
            
        @parameter
        if bWrap:
            @parameter
            if mask != 0:
                idx = idx & mask
            else:
                idx = idx % len(data)
            return data[idx]
        else:
            return data[idx] if ListInterpolator.idx_in_range(data,idx) else 0.0
        
    @always_inline
    @staticmethod
    fn read_linear[bWrap: Bool = True, mask: Int = 0](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a List[Float64] using provided index with linear interpolation."""
        
        idx0: Int64 = Int64(f_idx)
        idx1: Int64 = idx0 + 1
        frac: Float64 = f_idx - Float64(idx0)

        @parameter
        if bWrap:
            @parameter
            if mask != 0:
                idx0 = idx0 & mask
                idx1 = idx1 & mask
            else:
                length = len(data)
                idx0 = idx0 % length
                idx1 = idx1 % length
            
            y0 = data[idx0]
            y1 = data[idx1]

        else:
            # not wrapping
            y0 = data[idx0] if ListInterpolator.idx_in_range(data, idx0) else 0.0
            y1 = data[idx1] if ListInterpolator.idx_in_range(data, idx1) else 0.0

        return linear_interp(y0,y1,frac)

    @always_inline
    @staticmethod
    fn read_quad[bWrap: Bool = True, mask: Int = 0](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a List[Float64] using provided index with quadratic interpolation."""

        idx0 = Int64(f_idx)
        idx1 = idx0 + 1
        idx2 = idx0 + 2
        frac: Float64 = f_idx - Float64(idx0)

        @parameter
        if bWrap:
            @parameter
            if mask != 0:
                idx0 = idx0 & mask
                idx1 = idx1 & mask
                idx2 = idx2 & mask
            else:
                length = len(data)
                idx0 = idx0 % length
                idx1 = idx1 % length
                idx2 = idx2 % length

            y0 = data[idx0]
            y1 = data[idx1]
            y2 = data[idx2]

            return quadratic_interp(y0, y1, y2, frac)
        else:
            y0 = data[idx0] if ListInterpolator.idx_in_range(data, idx0) else 0.0
            y1 = data[idx1] if ListInterpolator.idx_in_range(data, idx1) else 0.0
            y2 = data[idx2] if ListInterpolator.idx_in_range(data, idx2) else 0.0

        return quadratic_interp(y0, y1, y2, frac)

    @always_inline
    @staticmethod
    fn read_sinc[bWrap: Bool = True, mask: Int = 0](w: UnsafePointer[MMMWorld], data: List[Float64], f_idx: Float64, prev_f_idx: Float64) -> Float64:
        return w[].sinc_interpolator.sinc_interp[bWrap,mask](data, f_idx, prev_f_idx)
