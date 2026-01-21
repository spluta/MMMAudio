from python import PythonObject
from python import Python
from .functions import *
from .MMMWorld_Module import MMMWorld, Interp
from math import sin, log2, ceil, floor
from sys import simd_width_of
from .functions import linear_interp, quadratic_interp

struct Buffer(Movable, Copyable):
    """A multi-channel audio buffer for storing audio data.

    Audio data is stored in the `data` variable as a `List[List[Float64]]`, where each inner `List` represents a channel of audio samples.
    """
    var data: List[List[Float64]]
    var num_chans: Int64 
    var num_frames: Int64
    var num_frames_f64: Float64
    var sample_rate: Float64
    var duration: Float64

    fn __init__(out self, data: List[List[Float64]], sample_rate: Float64):
        """Initialize a Buffer with the given audio data and sample rate.

        Args:
            data: A `List` of `List`s of `Float64` representing the audio data for each channel.
            sample_rate: The sample rate of the audio data.
        """

        if len(data) > 1:
            for chan in range(1,len(data)):
                if len(data[chan]) != len(data[0]):
                    print("Buffer::__init__ All channels must have the same number of frames")

        self.data = data.copy()
        self.sample_rate = sample_rate

        self.num_chans = len(data)
        self.num_frames = len(data[0]) if self.num_chans > 0 else 0
        self.num_frames_f64 = Float64(self.num_frames)
        self.duration = self.num_frames_f64 / self.sample_rate

    @staticmethod
    fn zeros(num_frames: Int64, num_chans: Int64 = 1, sample_rate: Float64 = 48000.0) -> Buffer:
        """Initialize a Buffer with zeros.

        Args:
            num_frames: Number of frames in the buffer.
            num_chans: Number of channels in the buffer.
            sample_rate: Sample rate of the buffer.
        """

        var data = List[List[Float64]]()
        for _ in range(num_chans):
            channel_data = List[Float64]()
            for _ in range(num_frames):
                channel_data.append(0.0)
            data.append(channel_data^)

        return Buffer(data, sample_rate)

    @staticmethod
    fn load(filename: String, num_wavetables: Int64 = 1) -> Buffer:
        """
        Initialize a Buffer by loading data from a WAV file using SciPy and NumPy.

        Args:
            filename: Path to the WAV file to load.
            num_wavetables: Number of wavetables per channel. This is only used if the sound file being loaded contains multiple wavetables concatenated in a single channel.
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

                self_sample_rate = Float64(Int(py_data[0]))  # Sample rate is the first element of the tuple

                if num_wavetables > 1:
                    # If num_wavetables is specified, calculate num_chans accordingly
                    total_samples = py_data[1].shape[0]
                    self_num_chans = num_wavetables
                    self_num_frames = Int(Float64(Int(total_samples)) / Float64(num_wavetables))
                else:
                    self_num_frames = Int(len(py_data[1]))  # num_frames is the length of the data array
                    if len(py_data[1].shape) == 1:
                        # Mono file
                        self_num_chans = 1
                    else:
                        # Multi-channel file
                        self_num_chans = Int(py_data[1].shape[1]) # Number of num_chans is the second dimension of the data array

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
                print("Buffer::__init__ Error loading file: ", filename, " Error: ", err)
                return Buffer.zeros(0,0,48000.0)
        else:
            print("Buffer::__init__ No filename provided")
            return Buffer.zeros(0,0,48000.0)

struct ListInterpolator(Movable, Copyable):
    """
    A collection of static methods for interpolating values from a `List[Float64]`.
    
    `ListInterpolator` supports various interpolation methods including
    
    * no interpolation (none)
    * linear interpolation
    * quadratic interpolation
    * cubic interpolation
    * lagrange interpolation (4th order)
    * sinc interpolation

    The available interpolation methods are defined in the struct [Interp](MMMWorld.md#struct-interp).
    """

    @always_inline
    @staticmethod
    fn idx_in_range(data: List[Float64], idx: Int64) -> Bool:
        return idx >= 0 and idx < len(data)

    # Once structs are allowed to have static variables, the since table will be stored in here so that 
    # a reference to the MMMWorld is not needed for every read call.
    @always_inline
    @staticmethod
    fn read[interp: Int = Interp.none, bWrap: Bool = True, mask: Int = 0](world: LegacyUnsafePointer[MMMWorld], data: List[Float64], f_idx: Float64, prev_f_idx: Float64 = 0.0) -> Float64:
        """Read a value from a List[Float64] using provided index and interpolation method, which is determined at compile time.
        
        Parameters:
            interp: Interpolation method to use (from [Interp](MMMWorld.md#struct-interp) enum).
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths).

        Args:
            world: Pointer to the MMMWorld instance.
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
            prev_f_idx: The previous floating-point index (used for [SincInterpolation](SincInterpolator.md)).
        """
        
        @parameter
        if interp == Interp.none:
            return ListInterpolator.read_none[bWrap,mask](data, f_idx)
        elif interp == Interp.linear:
            return ListInterpolator.read_linear[bWrap,mask](data, f_idx)
        elif interp == Interp.quad:
            return ListInterpolator.read_quad[bWrap,mask](data, f_idx)
        elif interp == Interp.cubic:
            return ListInterpolator.read_cubic[bWrap,mask](data, f_idx)
        elif interp == Interp.lagrange4:
            return ListInterpolator.read_lagrange4[bWrap,mask](data, f_idx)
        elif interp == Interp.sinc:
            return ListInterpolator.read_sinc[bWrap,mask](world,data, f_idx, prev_f_idx)
        else:
            print("ListInterpolator fn read:: Unsupported interpolation method")
            return 0.0

    @always_inline
    @staticmethod
    fn read_none[bWrap: Bool = True, mask: Int = 0](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a `List[Float64]` using provided index with no interpolation.
        
        Parameters:
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths).

        Args:
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
        """

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
        """Read a value from a `List[Float64]` using provided index with linear interpolation.
        
        Parameters:
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths).

        Args:
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
        """
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
        """Read a value from a `List[Float64]` using provided index with quadratic interpolation.
        
        Parameters:
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths).

        Args:
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
        """

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
    fn read_cubic[bWrap: Bool = True, mask: Int = 0](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a `List[Float64]` using provided index with cubic interpolation.
        
        Parameters:
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used. (only valid for power-of-two lengths).

        Args:
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
        """
        idx1 = Int64(f_idx)
        idx0 = idx1 - 1
        idx2 = idx1 + 1
        idx3 = idx1 + 2
        frac: Float64 = f_idx - Float64(idx1)

        @parameter
        if bWrap:
            @parameter
            if mask != 0:
                idx0 = idx0 & mask
                idx1 = idx1 & mask
                idx2 = idx2 & mask
                idx3 = idx3 & mask
            else:
                length = len(data)
                idx0 = idx0 % length
                idx1 = idx1 % length
                idx2 = idx2 % length
                idx3 = idx3 % length

            y0 = data[idx0]
            y1 = data[idx1]
            y2 = data[idx2]
            y3 = data[idx3]
            return cubic_interp(y0, y1, y2, y3, frac)
        else:
            y0 = data[idx0] if ListInterpolator.idx_in_range(data, idx0) else 0.0
            y1 = data[idx1] if ListInterpolator.idx_in_range(data, idx1) else 0.0
            y2 = data[idx2] if ListInterpolator.idx_in_range(data, idx2) else 0.0
            y3 = data[idx3] if ListInterpolator.idx_in_range(data, idx3) else 0.0
            return cubic_interp(y0, y1, y2, y3, frac)

    @always_inline
    @staticmethod
    fn read_lagrange4[bWrap: Bool = True, mask: Int = 0](data: List[Float64], f_idx: Float64) -> Float64:
        """Read a value from a `List[Float64]` using provided index with lagrange4 interpolation.
        
        Parameters:
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths).

        Args:
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
        """
       
        idx0 = Int64(f_idx)
        idx1 = idx0 + 1
        idx2 = idx0 + 2
        idx3 = idx0 + 3
        idx4 = idx0 + 4
        frac: Float64 = f_idx - Float64(idx0)

        @parameter
        if bWrap:
            @parameter
            if mask != 0:
                idx0 = idx0 & mask
                idx1 = idx1 & mask
                idx2 = idx2 & mask
                idx3 = idx3 & mask
                idx4 = idx4 & mask
            else:
                length = len(data)
                idx0 = idx0 % length
                idx1 = idx1 % length
                idx2 = idx2 % length
                idx3 = idx3 % length
                idx4 = idx4 % length

            y0 = data[idx0]
            y1 = data[idx1]
            y2 = data[idx2]
            y3 = data[idx3]
            y4 = data[idx4]
            # print(idx0,idx1,idx2,idx3,idx4,y0,y1,y2,y3,y4)
            return lagrange4(y0, y1, y2, y3, y4, frac)
        else:
            y0 = data[idx0] if ListInterpolator.idx_in_range(data, idx0) else 0.0
            y1 = data[idx1] if ListInterpolator.idx_in_range(data, idx1) else 0.0
            y2 = data[idx2] if ListInterpolator.idx_in_range(data, idx2) else 0.0
            y3 = data[idx3] if ListInterpolator.idx_in_range(data, idx3) else 0.0
            y4 = data[idx4] if ListInterpolator.idx_in_range(data, idx4) else 0.0
            return lagrange4(y0, y1, y2, y3, y4, frac)

    @always_inline
    @staticmethod
    fn read_sinc[bWrap: Bool = True, mask: Int = 0](world: LegacyUnsafePointer[MMMWorld], data: List[Float64], f_idx: Float64, prev_f_idx: Float64) -> Float64:
        """Read a value from a `List[Float64]` using provided index with [SincInterpolation](SincInterpolator.md).
        
        Parameters:
            bWrap: Whether to wrap indices that go out of bounds.
            mask: Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths).

        Args:
            world: Pointer to the MMMWorld instance.
            data: The `List[Float64]` to read from.
            f_idx: The floating-point index to read at.
            prev_f_idx: The previous floating-point index.
        """
        return world[].sinc_interpolator.sinc_interp[bWrap,mask](data, f_idx, prev_f_idx)
