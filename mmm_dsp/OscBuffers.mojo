from math import sin, log2, ceil, floor
from random import random_float64
from mmm_utils.functions import *
from memory import Pointer
from mmm_utils.Windows import build_sinc_table
from algorithm.functional import vectorize

struct Sinc_Interpolator(Representable, Movable, Copyable):
    var ripples: Int64  # Number of ripples for sinc interpolation
    var table: List[Float64]  # Sinc table for interpolation
    var table_size: Int64  # Size of the sinc table
    var sinc_points: List[Int64]  # Points for sinc interpolation
    var max_sinc_offset: Int64 
    var sinc_power: Int64  # Power for sinc interpolation

    fn __init__(out self, ripples: Int64 = 4, power: Int64 = 14):
        self.ripples = ripples
        self.sinc_power = power
        self.table_size = 2 ** power  # Size of the sinc table, e.g., 16384 for power 14
        self.table = build_sinc_table(self.table_size, ripples=self.ripples)  # Build sinc table with specified ripples
        self.max_sinc_offset = self.table_size // (self.ripples * 2)  # Calculate maximum sinc offset based on spacing

        self.sinc_points = List[Int64]()
        for i in range(self.table_size * 2):
            self.sinc_points.append(Int64(i * self.table_size/(self.ripples * 2)))  # Initialize sinc points based on the sinc table size

    fn __repr__(self) -> String:
        return String("Sinc_Interpolator(ripples: " + String(self.ripples) + ", table_size: " + String(self.table_size) + ")")

    fn next(self: Sinc_Interpolator, sp: Int64, sinc_offset: Int64, sinc_mult: Int64, frac: Float64) -> Float64:
        var sinc_indexA = self.sinc_points[sp] - (sinc_offset * sinc_mult)  # Get sinc index from the sinc points
        var sinc_indexB = sinc_indexA + 1  # Get the next sinc index
        var sinc_indexC = sinc_indexA + 2  # Get the next sinc index
        var sinc_value = quadratic_interpolation(
            self.table[sinc_indexA % self.table_size],
            self.table[sinc_indexB % self.table_size],
            self.table[sinc_indexC % self.table_size],
            frac
        )  # Interpolate sinc value using the sinc table

        return sinc_value  # Return the interpolated sinc value

struct OscBuffers(Representable, Movable, Copyable):
    var buffers: List[InlineArray[Float64, 16384]]  # List of all waveform buffers
    var sinc_interpolator: Sinc_Interpolator  # Sinc interpolator for waveform buffers
    var last_phase: Float64  # Last phase value for interpolation

    var size: Int64

    fn __init__(out self):
        self.size = 16384
        self.buffers = List[InlineArray[Float64, 16384]]()
        self.last_phase = 0.0  # Initialize last phase value
        self.sinc_interpolator = Sinc_Interpolator(4, 14)  # Initialize sinc interpolator with 4 ripples
        for _ in range(7):  # Initialize buffers for sine, triangle, square, and sawtooth
            self.buffers.append(InlineArray[Float64, 16384](fill=0.0))
        self.init_sine()  # Initialize sine wave buffer
        self.init_triangle()  # Initialize triangle wave buffer
        self.init_sawtooth()  # Initialize sawtooth wave buffer
        self.init_square()  # Initialize square wave buffer
        self.init_triangle2()  # Initialize triangle wave buffer using harmonics
        self.init_sawtooth2()  # Initialize sawtooth wave buffer using harmonics
        self.init_square2()  # Initialize square wave buffer using harmonics

        # self.sinc_table = List[Float64]()  # Initialize sinc table
        # self.sinc_table = build_sinc_table(16384, ripples=4)  # Build sinc table with 4 ripples

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

    fn quadratic_interp_loc(self, x: Float64, buf_num: Int64) -> Float64:
        # Ensure indices are within bounds
        var mod_idx = Int64(x) % Int64(self.size)
        var mod_idx1 = (mod_idx + 1) % Int64(self.size)
        var mod_idx2 = (mod_idx + 2) % Int64(self.size)

        # Get the fractional part
        var frac = x - Float64(Int64(x))

        # Get the 3 sample values
        var y0 = self.buffers[buf_num][mod_idx]
        var y1 = self.buffers[buf_num][mod_idx1]
        var y2 = self.buffers[buf_num][mod_idx2]

        return quadratic_interpolation(y0, y1, y2, frac)

    fn lin_interp(self, x: Float64, buf_num: Int64) -> Float64:
        # Get indices for 2 adjacent points
        var index = Int64(x)
        var index_next = (index + 1) % self.size
        
        # Get the fractional part
        var frac = x - Float64(index)
        
        # Get the 2 sample values
        var y0 = self.buffers[buf_num][index]
        var y1 = self.buffers[buf_num][index_next]
        # Linear interpolation formula: y0 + frac * (y1 - y0)
        return y0 + frac * (y1 - y0)

    # Get the next sample from the buffer using linear interpolation
    # Needs to receive an unsafe pointer to the buffer being used
    fn next_lin(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size)) % Float64(self.size)
        var value = self.lin_interp(f_index, buf_num)
        return value

    fn next_quadratic(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size)) % Float64(self.size)
        var value = self.quadratic_interp_loc(f_index, buf_num)
        return value

    fn next_sinc(self, phase: Float64, last_phase: Float64, buf_num: Int64) -> Float64:
        # Sinc interpolation using the sinc table
        var phase_diff = phase - last_phase  
        var slope = wrap(phase_diff, -0.5, 0.5)  
        var samples_per_frame = abs(slope) * Float64(self.size)  # Calculate samples per frame based on slope
        var octave = max(0.0, log2(samples_per_frame))
        octave = min(octave, Float64(self.sinc_interpolator.sinc_power) - 2.0) 

        var layer: Int64 = Int64(ceil(octave))  # Round up to the upper layer
        var sinc_crossfade: Float64 = octave - floor(octave) 

        if layer >= self.sinc_interpolator.sinc_power - 3:
            layer = self.sinc_interpolator.sinc_power - 3  # Limit layer to a maximum of self.sinc_interpolator.sinc_power - 3
            sinc_crossfade = 0.0  # Set crossfade to 0 if layer exceeds self.sinc_interpolator.sinc_power - 3
        var spacing1: Int64 = 2 ** layer
        var spacing2 = spacing1 * 2  # Calculate spacing for sinc interpolation

        var f_index = (phase * Float64(self.size)) % Float64(self.size)
        var index = Int64(f_index)  # Get the integer part of the index
        var frac = f_index - Float64(index)  # Get the fractional part

        var sinc1 = self.spaced_sinc(buf_num, index, frac, spacing1)  # Get the spaced sinc value
        if layer < 12:  # Check if layer is less than 12
            var sinc2 = self.spaced_sinc(buf_num, index, frac, spacing2)  # Get the spaced sinc value for double spacing
            return lin_interp(sinc1, sinc2, sinc_crossfade)  # Linear interpolation between sinc1 and sinc2
        else:
            return lin_interp(sinc1, 0.0, sinc_crossfade)  # Use sinc1 directly if spacing exceeds maximum sinc offset

    fn spaced_sinc(self, buf_num: Int64, index: Int64, frac: Float64, spacing: Int64) -> Float64:
        var sinc_mult: Int64 = self.sinc_interpolator.max_sinc_offset / spacing

        # var out: Float64 = 0.0  # Initialize output value
        var out: Float64 = 0.0

        for sp in range(0, self.sinc_interpolator.ripples * 2):
            var loc_point = (index + (sp - self.sinc_interpolator.ripples + 1) * spacing) % self.size  # Calculate location point in the buffer
            var spaced_point = (loc_point / spacing) * spacing
            var sinc_offset = loc_point - spaced_point  # Calculate sinc offset

            var sinc_value = self.sinc_interpolator.next(sp, sinc_offset, sinc_mult, frac)  # Get sinc value from the interpolator

            out += sinc_value * self.buffers[buf_num][spaced_point]

        return out  # Scale the sample by the sinc value

# one would think SIMD optimization would help here, but it doesn't
# it actually makes is worse!

#     fn spaced_sinc[simd_width: Int = 4](
#     self, 
#     buf_num: Int64, 
#     index: Int64, 
#     frac: Float64, 
#     spacing: Int64
# ) -> Float64:
#         var sinc_mult: Int64 = self.sinc_interpolator.max_sinc_offset / spacing
#         var loop_count = self.sinc_interpolator.ripples * 2
#         var num_chunks = loop_count // simd_width
#         # var remainder = loop_count % simd_width
        
#         var accumulator = SIMD[DType.float64, simd_width](0.0)
        
#             # Process SIMD chunks
#         var sinc_values = SIMD[DType.float64, simd_width](0.0)
#         var buffer_values = SIMD[DType.float64, simd_width](0.0)
            
#         for chunk in range(num_chunks):
#             var base_sp = chunk * simd_width
            
#             # Calculate all values for this chunk
#             for i in range(simd_width):
#                 var sp = base_sp + i
#                 var loc_point = (index + (sp - self.sinc_interpolator.ripples + 1) * spacing) % self.size
#                 var spaced_point = (loc_point / spacing) * spacing
#                 var sinc_offset = loc_point - spaced_point
                
#                 sinc_values[i] = self.sinc_interpolator.next(sp, sinc_offset, sinc_mult, frac)
#                 buffer_values[i] = self.buffers[buf_num][spaced_point]
            
#             # SIMD multiply-accumulate
#             accumulator += sinc_values * buffer_values
        
#         var out: Float64 = 0.0
#         for i in range(simd_width):
#             out += accumulator[i]
#         # # Handle remaining iterations - it should never run this code
#         # for sp in range(num_chunks * simd_width, loop_count):
#         #     var loc_point = (index + (sp - self.sinc_interpolator.ripples + 1) * spacing) % self.size
#         #     var spaced_point = (loc_point / spacing) * spacing
#         #     var sinc_offset = loc_point - spaced_point
#         #     var sinc_value = self.sinc_interpolator.next(sp, sinc_offset, sinc_mult, frac)
#         #     out += sinc_value * self.buffers[buf_num][spaced_point]
        
#         return out

    fn next(self, phase: Float64, osc_type: Int64 = 0, interp: Int64 = 0) -> Float64:
        if interp == 0:
            return self.next_lin(phase, osc_type)  # Linear interpolation
        elif interp == 1:
            return self.next_quadratic(phase, osc_type)  # Quadratic interpolation
        else:
            return self.next_lin(phase, osc_type)  # Default to linear interpolation
