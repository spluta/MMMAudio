from python import PythonObject
from python import Python
from memory import UnsafePointer
from mmm_utils.functions import *
from mmm_src.MMMWorld import MMMWorld
from math import sin, log2, ceil, floor
from sys import simd_width_of

alias dtype = DType.float64

struct Interp:
    alias none: Int = 0
    alias linear: Int = 1
    alias quad: Int = 2
    alias cubic: Int = 3
    alias lagrange: Int = 4
    alias sinc: Int = 5

struct Buffer(Movable, Copyable):

    var sample_rate: Float64  
    var data: List[List[Float64]]
    var num_chans: Int64
    var num_frames: Int64
    var num_frames_f: Float64
    
    fn __init__(out self, lists: List[List[Float64]], sample_rate: Float64 = 48000.0):

        self.data = lists.copy()
        self.num_chans = len(self.data)
        self.num_frames = len(self.data[0])
        self.num_frames_f = Float64(self.num_frames)
        self.sample_rate = sample_rate

    fn __init__(out self, list: List[Float64], sample_rate: Float64 = 48000.0):

        self.data = List[List[Float64]]()
        self.data.append(list.copy())
        self.num_chans = 1
        self.num_frames = len(self.data[0])
        self.num_frames_f = Float64(self.num_frames)
        self.sample_rate = sample_rate

    fn __repr__(self) -> String:
        return String("Buffer")

    fn at_index(self, index: Int64, chan: Int64 = 0) -> Float64:
        """Get a sample from the SoundFile at the specified index and channel."""

        if chan < 0 or chan >= self.num_chans or index < 0 or index >= self.num_frames:
            return 0.0
        else:
            return self.data[chan][index]

    @staticmethod
    def load(w: UnsafePointer[MMMWorld], filename: String, wavetables_per_channel: Int64 = 1) -> Buffer:
        """
        Initialize a Buffer by loading data from a WAV file using SciPy and NumPy.

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

        return Buffer(samples, buf_sample_rate)

struct Player(Movable, Copyable):
    """Buffer Player with interpolation support."""

    var w: UnsafePointer[MMMWorld]
    var prev_f_idx: Float64
    var f_idx: Float64

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.prev_f_idx = 0.0
        self.f_idx = 0.0

    fn next[num_chans: Int = 1, interp: Int = Interp.quad, wrap: Bool = False](mut self, buf: Buffer, rate: Float64 = 1, start_chan: Int64 = 0, trig: Bool = False) -> SIMD[DType.float64, num_chans]:

        if trig:
            self.f_idx = 0.0
        else:
            self.f_idx += rate * (buf.sample_rate / self.w[].sample_rate)

        if not wrap and (self.f_idx < 0.0 or self.f_idx >= buf.num_frames_f):
            return SIMD[DType.float64, num_chans](0.0)
        else:
            self.f_idx = self.f_idx % buf.num_frames_f

        # It is guaranteed that f_idx is now in range [0, num_frames_f)

        @parameter
        if interp == Interp.sinc:
            return self.sinc_interp[num_chans,wrap](buf,self.f_idx)
        else:
            out = SIMD[DType.float64, num_chans](0.0)
        
            @parameter
            for chan in range(num_chans):
                if (start_chan + chan) >= buf.num_chans:
                    # Out of bounds channel
                    out[chan] = 0.0
                else:
                    @parameter
                    if interp == Interp.none:
                        out[chan] = Player.read_none[wrap](buf.data[start_chan + chan], self.f_idx)
                    elif interp == Interp.linear:
                        out[chan] = Player.read_linear[wrap](buf.data[start_chan + chan], self.f_idx)
                    elif interp == Interp.quad:
                        out[chan] = Player.read_quad[wrap](buf.data[start_chan + chan], self.f_idx)
                    else:
                        # Unsupported interpolation method
                        print("fn read:: Unsupported interpolation method")
            return out

    @doc_private
    @always_inline
    fn sinc_interp[num_chans: Int = 1,wrap: Bool = False](mut self, buf: Buffer, f_idx: Float64) -> SIMD[DType.float64, num_chans]:
        """Read using provided index with sinc interpolation."""
        
        output = SIMD[DType.float64, num_chans](0.0)
        
        @parameter
        for chan in range(num_chans):
            if chan >= Int(buf.num_chans):
                output[chan] = 0.0
            else:
                output[chan] = self.w[].sinc_interpolator.sinc_interp[wrap](buf.data[chan], f_idx, self.prev_f_idx)
        
        # store previous index for next call
        self.prev_f_idx = f_idx

        return output

    # Reading Out Samples from a List[Float64] (a single channel)
    # =================================================================================

    @doc_private
    @always_inline
    @staticmethod
    fn read_quad[wrap: Bool = True](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a List[Float64] using provided index with quadratic interpolation."""

        # f_idx is guaranteed to be in range [0, len(data))
        # therefore wrap here is only useful to know if the indices being
        # used for interpolation should wrap or not

        idx0 = Int64(f_idx)
        idx1 = idx0 + 1
        idx2 = idx0 + 2
        frac: Float64 = f_idx - Float64(idx0)

        @parameter
        if wrap:
            y0 = data[idx0]
            y1 = data[idx1 % len(data)]
            y2 = data[idx2 % len(data)]
        else:
            y0 = data[idx0]
            y1 = data[idx1] if idx1 < len(data) else 0.0
            y2 = data[idx2] if idx2 < len(data) else 0.0

        return quadratic_interp(y0, y1, y2, frac)

    @doc_private
    @always_inline
    @staticmethod
    fn read_linear[wrap: Bool = True](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a List[Float64] using provided index with linear interpolation."""
        
        var wrapped_f_idx: Float64 = f_idx

        if f_idx < 0.0 or f_idx >= len(data):
            @parameter
            if wrap:
                wrapped_f_idx = f_idx % Float64(len(data))
            else:
                return 0.0  # Out of bounds
        
        idx0 = Int64(wrapped_f_idx)
        idx1 = idx0 + 1
        frac = wrapped_f_idx - Float64(idx0)

        @parameter
        if wrap:
            y0 = data[idx0]
            y1 = data[idx1 % len(data)]
        else:
            y0 = data[idx0]
            y1 = data[idx1] if idx1 < len(data) else 0.0

        return linear_interp(y0,y1,frac)

    @doc_private
    @always_inline
    @staticmethod
    fn read_none[wrap: Bool = True](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a List[Float64] using provided index with no interpolation."""
        return data[Int64(f_idx)]