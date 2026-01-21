from .Windows_Module import kaiser_window
from .functions import quadratic_interp
from .Buffer_Module import *
from sys import simd_width_of
from math import floor, log2, sin
from .functions import wrap, clip

struct SincInterpolator[ripples: Int64 = 4, power: Int64 = 14](Movable, Copyable):
    """Sinc Interpolation of `List[Float64]`s.

    Struct for high-quality audio resampling using sinc interpolation. This struct precomputes a sinc table and provides methods for performing sinc interpolation
    on audio data with adjustable ripples and table size. It is used in Osc for resampling oscillator signals.

    As a user, you won't need to interact with this struct directly. Instead use the [ListInterpolator](Buffer.md#struct-listinterpolator) struct.

    Parameters:
        ripples: Number of ripples in the sinc function, affecting interpolation quality.
        power: Power of two determining the size of the sinc table (table_size = 2^power).
    """
    var table: List[Float64]  # Sinc table for interpolation
    var table_size: Int64  # Size of the sinc table
    var mask: Int64  # Mask for wrapping indices
    var sinc_points: List[Int64]  # Points for sinc interpolation
    var max_sinc_offset: Int64 

    var sinc_power_f64: Float64
    var max_layer: Int64

    fn __init__(out self):
        self.table_size = 1 << self.power  # Size of the sinc table, e.g., 16384 for power 14 (using bit shift instead of exponentiation)
        self.mask = self.table_size - 1  # Mask for wrapping indices
        self.table = SincInterpolator.build_sinc_table(self.table_size)
        self.max_sinc_offset = self.table_size // (self.ripples * 2)  # Calculate maximum sinc offset based on spacing

        self.sinc_points = List[Int64]()
        for i in range(self.table_size * 2):
            self.sinc_points.append(Int64(i * self.table_size/(self.ripples * 2)))  # Initialize sinc points based on the sinc table size

        self.sinc_power_f64 = Float64(self.power)  # Assuming sinc_power is 14
        self.max_layer = self.power - 3

    fn __repr__(self) -> String:
        return String("SincInterpolator(ripples: " + String(self.ripples) + ", table_size: " + String(self.table_size) + ")")

    @doc_private
    @always_inline
    fn interp_points(self: SincInterpolator, sp: Int64, sinc_offset: Int64, sinc_mult: Int64, frac: Float64) -> Float64:
        """Helper function to perform quadratic interpolation on sinc table points."""
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

    @doc_private
    @always_inline  
    fn spaced_sinc[bWrap: Bool = False, mask: Int = 0](self, data: List[Float64], index: Int64, frac: Float64, spacing: Int64) -> Float64:
        """Read using spaced sinc interpolation. This is a helper function for read_sinc."""
        sinc_mult = self.max_sinc_offset / spacing
        loop_count = ripples * 2
        
        # Try to process in SIMD chunks if the loop is large enough
        comptime simd_width = simd_width_of[DType.float64]()
        var out: Float64 = 0.0
        data_len: Int64 = len(data)
        
        # Process SIMD chunks
        for base_sp in range(0, loop_count, simd_width):
            remaining = min(simd_width, loop_count - base_sp)
            
            @parameter
            for i in range(simd_width):
                if Int64(i) < remaining:
                    sp = base_sp + i
                    offset: Int64 = Int64(sp - ripples + 1)
                    
                    @parameter
                    if bWrap:
                        loc_point_unwrapped = index + offset * spacing
                        # loc_point = loc_point_unwrapped
                        
                        @parameter
                        if mask != 0:
                            loc_point = loc_point_unwrapped & mask
                        else:
                            loc_point = loc_point_unwrapped % data_len
                            if loc_point < 0:
                                loc_point += data_len

                        spaced_point = (loc_point / spacing) * spacing
                        sinc_offset = loc_point - spaced_point
                        
                        sinc_value = self.interp_points(sp, sinc_offset, sinc_mult, frac)
                        out += sinc_value * data[spaced_point]
                    else:
                        loc_point = index + offset * spacing
                        
                        # Check if the point is within bounds
                        if loc_point >= 0 and loc_point < data_len:
                            spaced_point = (loc_point / spacing) * spacing
                            sinc_offset = loc_point - spaced_point
                            
                            sinc_value = self.interp_points(sp, sinc_offset, sinc_mult, frac)
                            out += sinc_value * data[spaced_point]
                        # else: out of bounds, use 0.0 (zero padding) - no contribution to sum
    
        return out

    @always_inline
    fn sinc_interp[bWrap: Bool = True, mask: Int = 0](self, data: List[Float64], current_index: Float64, prev_index: Float64) -> Float64:
        """Perform sinc interpolation on the given data at the specified current index.
        
        Parameters:
            bWrap: Whether to wrap around at the end of the buffer when an index exceeds the buffer length.
            mask: Mask for wrapping indices if bWrap is True.
        
        Args:
            data: The audio data (Buffer channel) to interpolate.
            current_index: The current fractional index for interpolation.
            prev_index: The previous index. Needed to calculate the slope.
        """
        size_f64: Float64 = Float64(len(data))
        index_diff = current_index - prev_index
        half_window = size_f64 * 0.5
        
        @parameter
        if bWrap:
            slope_samples = wrap(index_diff, -half_window, half_window)  # Handle circular buffer wrap
        else:
            slope_samples = index_diff  # No wrapping
        
        samples_per_frame = abs(slope_samples)
        
        octave = clip(log2(samples_per_frame), 0.0, self.sinc_power_f64 - 2.0)
        octave_floor = floor(octave)
        
        var layer = Int64(octave_floor + 1.0)
        var sinc_crossfade = octave - octave_floor
        
        var layer_clamped = min(layer, self.max_layer)
        selector: SIMD[DType.bool, 1] = (layer >= self.max_layer)
        sinc_crossfade = selector.select(0.0, sinc_crossfade)
        layer = layer_clamped
        
        spacing1: Int64 = Int64(1) << layer
        spacing2: Int64 = spacing1 << 1
        
        f_index = current_index
        index_floor = Int64(f_index)
        frac = f_index - Float64(index_floor)
        
        sinc1 = self.spaced_sinc[bWrap,mask](data, index_floor, frac, spacing1)
        
        sel0: SIMD[DType.bool, 1] = (sinc_crossfade == 0.0)
        sel1: SIMD[DType.bool, 1] = (layer < 12)
        sinc2 = sel0.select(0.0, sel1.select(self.spaced_sinc[bWrap,mask](data, index_floor, frac, spacing2),0.0))
        
        return sinc1 + sinc_crossfade * (sinc2 - sinc1)

    @doc_private
    @staticmethod
    fn build_sinc_table(table_size: Int64) -> List[Float64]:
        
        # Create evenly spaced points - the width is determined by ripples
        var width = Float64(ripples)
        # Create evenly spaced x values from -width*π to width*π
        var x_values = List[Float64]()

        var x_min = -width * 3.141592653589793
        var x_max = width * 3.141592653589793
        var step = (x_max - x_min) / Float64(table_size - 1)
        
        for i in range(table_size):
            x_values.append(x_min + step * Float64(i))

        table = List[Float64]()

        for i in range(len(x_values)):
            if x_values[i] == 0:
                table.append(1.0)
            else:
                table.append(sin(x_values[i]) / x_values[i])

        # Apply Kaiser window to the sinc table
        # The beta parameter controls the trade-off between main lobe width and side lobe height
        beta = 5.0  # Typical values range from 5 to 8 for audio processing

        window = kaiser_window(table_size, beta)
        for i in range(len(table)):
            table[i] *= window[i]  # Apply the window to the sinc values
        
        return table.copy()