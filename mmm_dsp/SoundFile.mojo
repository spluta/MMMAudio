from python import PythonObject
from python import Python
from mmm_utils.functions import *
from mmm_src.MMMWorld import *
from math import sin, log2, ceil, floor
from sys import simd_width_of
from mmm_utils.functions import linear_interp, quadratic_interp

alias dtype = DType.float64

struct SoundFile(Movable, Copyable):

    var data: List[List[Float64]]
    var num_chans: Int64
    var num_frames: Int64
    var num_frames_f64: Float64
    var sample_rate: Float64
    
    def __init__(out self, filename: String, num_wavetables: Int64 = 1):
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

        if filename != "":
            # Load the file if a filename is provided
            try:
                py_data = scipy.io.wavfile.read(filename)  # Read the WAV file using SciPy

                print(py_data)  # Print the loaded data for debugging

                self.sample_rate = Float64(py_data[0])  # Sample rate is the first element of the tuple

                if num_wavetables > 1:
                    # If num_wavetables is specified, calculate num_chans accordingly
                    total_samples = py_data[1].shape[0]
                    self.num_chans = num_wavetables
                    self.num_frames = Int64(Float64(total_samples) / Float64(num_wavetables))
                else:
                    self.num_frames = Int64(len(py_data[1]))  # num_frames is the length of the data array
                    if len(py_data[1].shape) == 1:
                        # Mono file
                        self.num_chans = 1
                    else:
                        # Multi-channel file
                        self.num_chans = Int64(Float64(py_data[1].shape[1]))  # Number of num_chans is the second dimension of the data array

                self.num_frames_f64 = Float64(self.num_frames)
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

                # wavetables are stored in ordered channels, not interleaved
                if num_wavetables > 1:
                    for c in range(self.num_chans):
                        channel_data = List[Float64]()
                        for f in range(Int64(self.num_frames)):
                            channel_data.append(data_ptr[(c * Int64(self.num_frames)) + f])
                        self.data.append(channel_data^)
                else:
                    # normal multi-channel interleaved data
                    for c in range(self.num_chans):
                        channel_data = List[Float64]()
                        for f in range(Int64(self.num_frames)):
                            channel_data.append(data_ptr[(f * self.num_chans) + c])
                        self.data.append(channel_data^)

                print("Buffer initialized with file:", filename)  # Print the filename for debugging
            except err:
                raise Error("Buffer::__init__ Error loading file: ", filename, " Error: ", err)
        else:
            raise Error("SoundFile::__init__ No filename provided")

    # I'm pretty sure this is completely unnecessary now
    # ==================================================
    # @always_inline
    # fn read[num_chans: Int = 1, interp: Int = Interp.quad, bWrap: Bool = False, mask: Int = 0](mut self, f_idx: Float64, start_chan: Int64 = 0, prev_f_idx: Float64 = 0.0) -> SIMD[DType.float64, num_chans]:

    #     out = SIMD[DType.float64, num_chans](0.0)
    
    #     @parameter
    #     for chan in range(num_chans):
    #         if (start_chan + chan) >= self.num_chans:
    #             out[chan] = 0.0
    #         else:
    #             out[chan] = ListFloat64Reader.read[interp=interp,bWrap=bWrap,mask=mask](self.w, self.data[start_chan + chan], f_idx, prev_f_idx)

    #     return out

struct ListFloat64Reader(Movable, Copyable):

    @always_inline
    @staticmethod
    fn idx_in_range(data: List[Float64], idx: Int64) -> Bool:
        return idx >= 0 and idx < len(data)

    @always_inline
    @staticmethod
    fn read[interp: Int = Interp.none, bWrap: Bool = True, mask: Int = 0](w: UnsafePointer[MMMWorld], data: List[Float64], f_idx: Float64, prev_f_idx: Float64 = 0.0) -> Float64:
        """Read a value from a List[Float64] using provided index and interpolation method."""
        
        @parameter
        if interp == Interp.none:
            return ListFloat64Reader.read_none[bWrap,mask](data, f_idx)
        elif interp == Interp.linear:
            return ListFloat64Reader.read_linear[bWrap,mask](data, f_idx)
        elif interp == Interp.quad:
            return ListFloat64Reader.read_quad[bWrap,mask](data, f_idx)
        elif interp == Interp.sinc:
            return ListFloat64Reader.read_sinc[bWrap,mask](w,data, f_idx, prev_f_idx)
        else:
            print("ListFloat64Reader fn read:: Unsupported interpolation method")
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
            return data[idx] if ListFloat64Reader.idx_in_range(data,idx) else 0.0
        
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
            y0 = data[idx0] if ListFloat64Reader.idx_in_range(data, idx0) else 0.0
            y1 = data[idx1] if ListFloat64Reader.idx_in_range(data, idx1) else 0.0

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
            y0 = data[idx0] if ListFloat64Reader.idx_in_range(data, idx0) else 0.0
            y1 = data[idx1] if ListFloat64Reader.idx_in_range(data, idx1) else 0.0
            y2 = data[idx2] if ListFloat64Reader.idx_in_range(data, idx2) else 0.0

        return quadratic_interp(y0, y1, y2, frac)

    @always_inline
    @staticmethod
    fn read_sinc[bWrap: Bool = True, mask: Int = 0](w: UnsafePointer[MMMWorld], data: List[Float64], f_idx: Float64, prev_f_idx: Float64) -> Float64:
        return w[].sinc_interpolator.sinc_interp[bWrap,mask](data, f_idx, prev_f_idx)
