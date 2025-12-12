from python import PythonObject
from python import Python
from mmm_utils.functions import *
from mmm_src.MMMWorld import *
from math import sin, log2, ceil, floor
from sys import simd_width_of
from mmm_utils.functions import linear_interp, quadratic_interp

alias dtype = DType.float64

struct SoundFile(Movable, Copyable):

    var w: UnsafePointer[MMMWorld]
    var sample_rate: Float64  
    var data: List[List[Float64]]
    var num_chans: Int64
    var num_frames: Int64
    var num_frames_f64: Float64
    
    fn __init__(out self, w: UnsafePointer[MMMWorld], lists: List[List[Float64]], sample_rate: Float64 = 48000.0):

        self.w = w
        self.data = lists.copy()
        self.num_chans = len(self.data)
        self.num_frames = len(self.data[0])
        self.num_frames_f64 = Float64(self.num_frames)
        self.sample_rate = sample_rate

    fn __init__(out self, w: UnsafePointer[MMMWorld], list: List[Float64], sample_rate: Float64 = 48000.0):

        self.w = w
        self.data = List[List[Float64]]()
        self.data.append(list.copy())
        self.num_chans = 1
        self.num_frames = len(self.data[0])
        self.num_frames_f64 = Float64(self.num_frames)
        self.sample_rate = sample_rate

    fn __repr__(self) -> String:
        return String("Buffer")

    @staticmethod
    def load(w: UnsafePointer[MMMWorld], filename: String, wavetables_per_channel: Int64 = 1) -> SoundFile:
        """
        Initialize a SoundFile by loading data from a WAV file using SciPy and NumPy.

        Args:
            w: UnsafePointer to MMMWorld.
            filename: Path to the WAV file to load.
            wavetables_per_channel: Number of wavetables per channel. Default is 1, meaning normal audio file loading. This is used only when the file is a multi-wavetable file, meaning it (probably) contains 1 channel of audio but is comprised of concatenated wavetables (back to back). See the [TODO] file for an applicable example.
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
                num_chans = 1
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

        samples = List[List[Float64]]()
        # wavetables are stored in ordered channels, not interleaved
        if wavetables_per_channel > 1:
            for c in range(num_chans):
                channel_data = List[Float64]()
                for f in range(Int64(num_frames)):
                    channel_data.append(data_ptr[(c * Int64(num_frames)) + f])
                samples.append(channel_data^)
        else:
            # normal multi-channel interleaved data
            for c in range(num_chans):
                channel_data = List[Float64]()
                for f in range(Int64(num_frames)):
                    channel_data.append(data_ptr[(f * num_chans) + c])
                samples.append(channel_data^)

        return Buffer(w,samples, buf_sample_rate)

    @always_inline
    fn read[num_chans: Int = 1, interp: Int = Interp.quad, bWrap: Bool = False, mask: Int = 0](mut self, f_idx: Float64, start_chan: Int64 = 0, prev_f_idx: Float64 = 0.0) -> SIMD[DType.float64, num_chans]:

        out = SIMD[DType.float64, num_chans](0.0)
    
        @parameter
        for chan in range(num_chans):
            if (start_chan + chan) >= self.num_chans:
                out[chan] = 0.0
            else:
                out[chan] = ListFloat64Reader.read[bWrap,mask](self.w, self.data[start_chan + chan], f_idx, prev_f_idx)

        return out

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
