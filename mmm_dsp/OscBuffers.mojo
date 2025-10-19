from math import sin, log2, ceil, floor
from random import random_float64
from mmm_utils.functions import *
from memory import Pointer
from mmm_utils.Windows import build_sinc_table
from algorithm.functional import vectorize
from sys import simd_width_of

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
        self.table_size = 1 << power  # Size of the sinc table, e.g., 16384 for power 14 (using bit shift instead of exponentiation)
        self.table = build_sinc_table(self.table_size, ripples=self.ripples)  # Build sinc table with specified ripples
        self.max_sinc_offset = self.table_size // (self.ripples * 2)  # Calculate maximum sinc offset based on spacing

        self.sinc_points = List[Int64]()
        for i in range(self.table_size * 2):
            self.sinc_points.append(Int64(i * self.table_size/(self.ripples * 2)))  # Initialize sinc points based on the sinc table size

    fn __repr__(self) -> String:
        return String("Sinc_Interpolator(ripples: " + String(self.ripples) + ", table_size: " + String(self.table_size) + ")")

    fn next(self: Sinc_Interpolator, sp: Int64, sinc_offset: Int64, sinc_mult: Int64, frac: Float64) -> Float64:
        var sinc_indexA = self.sinc_points[sp] - (sinc_offset * sinc_mult)
        var sinc_indexB = sinc_indexA + 1
        var sinc_indexC = sinc_indexA + 2
        var sinc_value = quadratic_interp(
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
    @always_inline
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

        return quadratic_interp(y0, y1, y2, frac)
    @always_inline
    fn lerp(self, x: Float64, buf_num: Int64) -> Float64:
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
    @always_inline
    fn read_lin(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size)) % Float64(self.size)
        var value = self.lerp(f_index, buf_num)
        return value

    @always_inline
    fn read_quadratic(self, phase: Float64, buf_num: Int64) -> Float64:
        var f_index = (phase * Float64(self.size)) % Float64(self.size)
        var value = self.quadratic_interp_loc(f_index, buf_num)
        return value

    @always_inline
    fn read_sinc(self, phase: Float64, last_phase: Float64, buf_num: Int64) -> Float64:
        # Pre-compute constants to avoid repeated conversions
        size_f64 = Float64(self.size)
        sinc_power_f64 = Float64(self.sinc_interpolator.sinc_power)
        max_layer = self.sinc_interpolator.sinc_power - 3
        
        # Compute phase difference and slope
        phase_diff = phase - last_phase  
        slope = wrap(phase_diff, -0.5, 0.5)  
        samples_per_frame = abs(slope) * size_f64
        
        # Compute octave with single clamp operation
        octave = clip(log2(samples_per_frame), 0.0, sinc_power_f64 - 2.0)
        
        # Compute layer and crossfade
        octave_floor = floor(octave)
        var layer = Int64(octave_floor + 1.0) 
        var sinc_crossfade = octave - octave_floor
        
        # Clamp layer and adjust crossfade
        if layer >= max_layer:
            layer = max_layer
            sinc_crossfade = 0.0
        
        # Use bit shifts for powers of 2 (much faster)
        spacing1 = 1 << layer
        spacing2 = spacing1 << 1
        
        # Compute index and fraction
        f_index = (phase * size_f64) % size_f64
        index = Int64(f_index)
        frac = f_index - Float64(index)
        
        # Get first sinc value
        sinc1 = self.spaced_sinc(buf_num, index, frac, spacing1)
        
        # Early return optimization for crossfade = 0
        if sinc_crossfade == 0.0:
            return sinc1
        
        # Conditional interpolation
        if layer < 12:
            sinc2 = self.spaced_sinc(buf_num, index, frac, spacing2)
            return sinc1 + sinc_crossfade * (sinc2 - sinc1)  # Optimized lerp
        else:
            return sinc1 * (1.0 - sinc_crossfade)  # Optimized lerp with 0

    @always_inline  
    fn spaced_sinc(self, buf_num: Int64, index: Int64, frac: Float64, spacing: Int64) -> Float64:
        sinc_mult = self.sinc_interpolator.max_sinc_offset / spacing
        ripples = self.sinc_interpolator.ripples
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
                    loc_point = (index + offset * spacing) % self.size
                    spaced_point = (loc_point / spacing) * spacing
                    sinc_offset = loc_point - spaced_point
                    
                    sinc_value = self.sinc_interpolator.next(sp, sinc_offset, sinc_mult, frac)
                    out += sinc_value * self.buffers[buf_num][spaced_point]
        
        return out

    fn read[interp: Int = 0](self, phase: Float64, osc_type: Int64 = 0) -> Float64:
        @parameter
        if interp == 0:
            return self.read_lin(phase, osc_type)  # Linear interpolation
        elif interp == 1:
            return self.read_quadratic(phase, osc_type)  # Quadratic interpolation
        else:
            return self.read_lin(phase, osc_type)  # Default to linear interpolation
