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

struct Buffer(Buffable):
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

    var sinc_interpolator: Sinc_Interpolator[4, 14]

    fn get_num_frames(self) -> Float64:
        return Float64(self.num_frames)

    fn get_item(self, chan_index: Int64, frame_index: Int64) -> Float64:
        return self.data[chan_index][frame_index]

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

        self.sinc_interpolator = Sinc_Interpolator[4, 14](Int(self.num_frames))


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

        self.sinc_interpolator = Sinc_Interpolator[4, 14](Int(self.num_frames))
        
    fn __init__(out self, filename: String, chans_per_channel: Int64 = 1):
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

                print(py_data)  # Print the loaded data for debugging

                self.buf_sample_rate = Float64(py_data[0])  # Sample rate is the first element of the tuple



                if chans_per_channel > 1:
                    # If chans_per_channel is specified, calculate num_chans accordingly
                    total_samples = py_data[1].shape[0]
                    self.num_chans = chans_per_channel
                    self.num_frames = Float64(total_samples) / Float64(chans_per_channel)
                    self.duration = self.num_frames / self.buf_sample_rate  # Calculate duration in seconds
                else:
                    self.num_frames = Float64(len(py_data[1]))  # num_frames is the length of the data array
                    self.duration = self.num_frames / self.buf_sample_rate  # Calculate duration in seconds
                    if len(py_data[1].shape) == 1:
                        # Mono file
                        self.num_chans = 1
                    else:
                        # Multi-channel file
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

                # wavetables are stored in ordered channels, not interleaved
                if chans_per_channel > 1:
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
                print("Buffer::__init__ Error loading file: ", filename, " Error: ", err)
                self.num_frames = 0.0
                self.num_chans = 0
        else:
            self.num_frames = 0.0
            self.buf_sample_rate = 48000.0  # Default sample rate

        self.sinc_interpolator = Sinc_Interpolator[4, 14](Int(self.num_frames))

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

    @always_inline
    fn read_phase_none(self, phase: Float64, chan: Int64) -> Float64:
        """read one sample with no interpolation."""
        # Ensure indices are within bounds
        var idx = Int(phase * self.num_frames)
        var mod_idx = idx % (Int64(self.num_frames))

        # Get the 2 sample values
        var y0 = self.data[chan][mod_idx]
        return y0

    @always_inline
    fn read_sinc(self,phase: Float64, last_phase: Float64, channel: Int64) -> Float64:
        return self.sinc_interpolator.read_sinc(self, phase, last_phase, channel)

    @always_inline
    fn read_index[N: Int = 1, interp: Int64 = 0](self, start_chan: Int64, f_idx: Float64) -> SIMD[DType.float64, N]:
        if self.num_frames == 0 or self.num_chans == 0:
            return SIMD[DType.float64, N](0.0)  # Return zero if no frames or channels are available
        
        var frac = f_idx - Float64(Int64(f_idx))

        var idx = Int64(f_idx)

        if idx < 0 or idx >= Int64(self.num_frames):
            return SIMD[DType.float64, N](0.0)  # Out of bounds

        var out = SIMD[DType.float64, N](0.0)
        @parameter
        for i in range(N):
            @parameter
            if interp == 0:
                out[i] = self.linear_interp_loc(idx, idx + 1, frac, start_chan + i)
            elif interp == 1:
                out[i] = self.quadratic_interp_loc(idx, (idx + 1), (idx + 2), frac, start_chan + i)
            else:
                out[i] = self.linear_interp_loc(idx, idx + 1, frac, start_chan + i)  # default is linear interpolation
        return out

    @always_inline
    fn read_phase[N: Int = 1, interp: Int64 = 0](self, start_chan: Int64, phase: Float64) -> SIMD[DType.float64, N]:
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
        
        return self.read_index[N, interp](start_chan, f_idx)

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
            return  # Out of bounds [TODO]: throw warning
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
            None.
        """

        self.write[N=N](value, Int64(self.index), start_channel)
        self.index += 1.0
        if self.index >= self.num_frames:
            self.index = 0.0

struct Sinc_Interpolator[ripples: Int64 = 4, power: Int64 = 14](Movable, Copyable):
    var table: List[Float64]  # Sinc table for interpolation
    var table_size: Int64  # Size of the sinc table
    var mask: Int64  # Mask for wrapping indices
    var sinc_points: List[Int64]  # Points for sinc interpolation
    var max_sinc_offset: Int64 

    var size_f64: Float64
    var sinc_power_f64: Float64
    var max_layer: Int64
    var size_f64_inv: Float64


    fn __init__(out self, num_frames: Int64):

        self.table_size = 1 << self.power  # Size of the sinc table, e.g., 16384 for power 14 (using bit shift instead of exponentiation)
        self.mask = self.table_size - 1  # Mask for wrapping indices
        self.table = build_sinc_table(self.table_size, ripples=self.ripples)  # Build sinc table with specified ripples
        self.max_sinc_offset = self.table_size // (self.ripples * 2)  # Calculate maximum sinc offset based on spacing

        self.sinc_points = List[Int64]()
        for i in range(self.table_size * 2):
            self.sinc_points.append(Int64(i * self.table_size/(self.ripples * 2)))  # Initialize sinc points based on the sinc table size

        self.size_f64 = Float64(num_frames)
        self.sinc_power_f64 = Float64(self.power)  # Assuming sinc_power is 14
        self.max_layer = self.power - 3
        self.size_f64_inv = 1.0 / Float64(num_frames)

    fn __repr__(self) -> String:
        return String("Sinc_Interpolator(ripples: " + String(self.ripples) + ", table_size: " + String(self.table_size) + ")")

    fn interp_points(self: Sinc_Interpolator, sp: Int64, sinc_offset: Int64, sinc_mult: Int64, frac: Float64) -> Float64:
        sinc_indexA = self.sinc_points[sp] - (sinc_offset * sinc_mult)
        
        idxA = sinc_indexA & self.mask
        idxB = (sinc_indexA + 1) & self.mask
        idxC = (sinc_indexA + 2) & self.mask
        
        return quadratic_interp(
            self.table[idxA],
            self.table[idxB], 
            self.table[idxC],
            frac
        )

    @always_inline  
    fn spaced_sinc[T: Buffable](self, ref buffer: T, channel: Int64, index: Int64, frac: Float64, spacing: Int64) -> Float64:
        sinc_mult = self.max_sinc_offset / spacing
        ripples = self.ripples
        loop_count = ripples * 2
        
        # Try to process in SIMD chunks if the loop is large enough
        alias simd_width = simd_width_of[DType.float64]()
        var out: Float64 = 0.0
        
        # Process SIMD chunks
        for base_sp in range(0, loop_count, simd_width):
            remaining = min(simd_width, loop_count - base_sp)
            
            @parameter
            for i in range(simd_width):
                if Int64(i) < remaining:
                    sp = base_sp + i
                    offset = sp - ripples + 1
                    loc_point = (index + offset * spacing) % Int(buffer.get_num_frames())
                    spaced_point = (loc_point / spacing) * spacing
                    sinc_offset = loc_point - spaced_point
                    
                    sinc_value = self.interp_points(sp, sinc_offset, sinc_mult, frac)
                    out += sinc_value * buffer.get_item(channel, spaced_point)
        
        return out

    @always_inline
    fn read_sinc[T: Buffable](self, ref buffer: T,phase: Float64, last_phase: Float64, channel: Int64) -> Float64:
        phase_diff = phase - last_phase  
        slope = wrap(phase_diff, -0.5, 0.5)  
        samples_per_frame = abs(slope) * self.size_f64
        
        octave = clip(log2(samples_per_frame), 0.0, self.sinc_power_f64 - 2.0)
        octave_floor = floor(octave)
        
        var layer = Int64(octave_floor + 1.0)
        var sinc_crossfade = octave - octave_floor
        
        var layer_clamped = min(layer, self.max_layer)
        selector: SIMD[DType.bool, 1] = (layer >= self.max_layer)
        sinc_crossfade = selector.select(0.0, sinc_crossfade)
        layer = layer_clamped
        
        spacing1 = 1 << layer
        spacing2 = spacing1 << 1
        
        f_index = phase * self.size_f64
        index = Int64(f_index)
        frac = f_index - Float64(index)
        
        sinc1 = self.spaced_sinc(buffer, channel, index, frac, spacing1)
        
        sel0: SIMD[DType.bool, 1] = (sinc_crossfade == 0.0)
        sel1: SIMD[DType.bool, 1] = (layer < 12)
        sinc2 = sel0.select(0.0, 
                    sel1.select(
                            self.spaced_sinc(buffer, channel, index, frac, spacing2),
                            0.0)
                )
        
        return sinc1 + sinc_crossfade * (sinc2 - sinc1)

struct OscBuffers(Buffable):
    var buffers: InlineArray[InlineArray[Float64, 16384], 7]  # List of all waveform buffers
    var sinc_interpolator: Sinc_Interpolator[4, 14]  # Sinc interpolator for waveform buffers
    var last_phase: Float64  # Last phase value for interpolation
    var size: Int64
    var mask: Int64

    fn get_num_frames(self) -> Float64:
        return Float64(self.size)

    fn get_item(self, chan_index: Int64, frame_index: Int64) -> Float64:
        return self.buffers[chan_index][frame_index]

    fn __init__(out self):
        self.size = 16384
        self.mask = self.size - 1
        self.buffers = InlineArray[InlineArray[Float64, 16384], 7](uninitialized=True)
        self.last_phase = 0.0  # Initialize last phase value
        
        self.sinc_interpolator = Sinc_Interpolator[4, 14](self.size)
        
        self.init_sine()  # Initialize sine wave buffer
        self.init_triangle()  # Initialize triangle wave buffer
        self.init_sawtooth()  # Initialize sawtooth wave buffer
        self.init_square()  # Initialize square wave buffer
        self.init_triangle2()  # Initialize triangle wave buffer using harmonics
        self.init_sawtooth2()  # Initialize sawtooth wave buffer using harmonics
        self.init_square2()  # Initialize square wave buffer using harmonics

    fn init_sine(mut self: OscBuffers):
        for i in range(self.size):
            self.buffers[0][i] = (sin(2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)))  # Precompute sine values

    fn init_triangle(mut self: OscBuffers):
        for i in range(self.size):
            if i < self.size // 2:
                self.buffers[1][i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Ascending part
            else:
                self.buffers[1][i] = 1.0 - 2.0 * (Float64(i) / Float64(self.size))  # Descending part

    fn init_sawtooth(mut self: OscBuffers):
        for i in range(self.size):
            self.buffers[2][i] = 2.0 * (Float64(i) / Float64(self.size)) - 1.0  # Linear ramp from -1 to 1

    fn init_square(mut self: OscBuffers):
        for i in range(self.size):
            if i < self.size // 2:
                self.buffers[3][i] = 1.0  # First half is 1
            else:
                self.buffers[3][i] = -1.0  # Second half is -1

    fn init_triangle2(mut self: OscBuffers):
        # Construct triangle wave from sine harmonics
        # Triangle formula: 8/pi^2 * sum((-1)^(n+1) * sin(n*x) / n^2) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / (Float64(n) * Float64(n))
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 8/π² for correct amplitude
            self.buffers[4][i] = 8.0 / (3.141592653589793 * 3.141592653589793) * sample

    fn init_sawtooth2(mut self: OscBuffers):
        # Construct sawtooth wave from sine harmonics
        # Sawtooth formula: 2/pi * sum((-1)^(n+1) * sin(n*x) / n) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(n) * x) / Float64(n)
                if n % 2 == 0:  # (-1)^(n+1) is -1 when n is even
                    harmonic = -harmonic
                sample += harmonic
            
            # Scale by 2/π for correct amplitude
            self.buffers[5][i] = 2.0 / 3.141592653589793 * sample

    fn init_square2(mut self: OscBuffers):
        # Construct square wave from sine harmonics
        # Square formula: 4/pi * sum(sin((2n-1)*x) / (2n-1)) for n=1 to 512
        for i in range(self.size):
            var x = 2.0 * 3.141592653589793 * Float64(i) / Float64(self.size)
            var sample: Float64 = 0.0
            
            for n in range(1, 513):  # Using 512 harmonics
                var harmonic = sin(Float64(2 * n - 1) * x) / Float64(2 * n - 1)
                sample += harmonic
            
            # Scale by 4/π for correct amplitude
            self.buffers[6][i] = 4.0 / 3.141592653589793 * sample

    fn __repr__(self) -> String:
        return String(
            "OscBuffers(size=" + String(self.size) + ")"
        )
    @always_inline
    fn quadratic_interp_loc(self, x: Float64, buf_num: Int64) -> Float64:
        base_idx = Int64(x) & self.mask
        idx1 = (base_idx + 1) & self.mask
        idx2 = (base_idx + 2) & self.mask
        
        frac = x - Float64(Int64(x))
        
        ref buffer = self.buffers[buf_num]
        return quadratic_interp(buffer[base_idx], buffer[idx1], buffer[idx2], frac)

    @always_inline
    fn lerp(self, x: Float64, buf_num: Int64) -> Float64:
        index = Int64(x) & self.mask
        index_next = (index + 1) & self.mask
        frac = x - Float64(Int64(x))
        
        ref buffer = self.buffers[buf_num]
        return buffer[index] + frac * (buffer[index_next] - buffer[index])
    
    @always_inline
    fn read_none(self, phase: Float64, buf_num: Int64) -> Float64:
        index = Int64(phase * Float64(self.size)) & self.mask
        
        return self.buffers[buf_num][index]

    # Get the next sample from the buffer using linear interpolation
    # Needs to receive an unsafe pointer to the buffer being used
    @always_inline
    fn read_lin(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size))
        var value = self.lerp(f_index, buf_num)
        return value

    @always_inline
    fn read_quadratic(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size))
        var value = self.quadratic_interp_loc(f_index, buf_num)
        return value

    fn read[interp: Int = 0](self, phase: Float64, osc_type: Int64 = 0) -> Float64:
        @parameter
        if interp == 0:
            return self.read_lin(phase, osc_type)  # Linear interpolation
        elif interp == 1:
            return self.read_quadratic(phase, osc_type)  # Quadratic interpolation
        else:
            return self.read_lin(phase, osc_type)  # Default to linear interpolation

    @always_inline
    fn read_sinc(self,phase: Float64, last_phase: Float64, channel: Int64) -> Float64:
        return self.sinc_interpolator.read_sinc(self, phase, last_phase, channel)