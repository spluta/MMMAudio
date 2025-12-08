from mmm_utils.Windows import build_sinc_table
from mmm_utils.functions import quadratic_interp
from mmm_dsp.Buffer import Buffable

struct SincInterpolator[ripples: Int64 = 4, power: Int64 = 14](Movable, Copyable):
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
        self.table = build_sinc_table(self.table_size, ripples=self.ripples)  # Build sinc table with specified ripples
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
    fn read_sinc[T: Buffable](self, ref buffer: T, current_index: Float64, prev_index: Float64, channel: Int64) -> Float64:
        index_diff = current_index - prev_index
        half_window = self.size_f64 * 0.5
        slope_samples = wrap(index_diff, -half_window, half_window)  # Handle circular buffer wrap
        samples_per_frame = abs(slope_samples)
        
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
        
        f_index = current_index
        index_floor = Int64(f_index)
        frac = f_index - Float64(index_floor)
        
        sinc1 = self.spaced_sinc(buffer, channel, index_floor, frac, spacing1)
        
        sel0: SIMD[DType.bool, 1] = (sinc_crossfade == 0.0)
        sel1: SIMD[DType.bool, 1] = (layer < 12)
        sinc2 = sel0.select(0.0, sel1.select(self.spaced_sinc(buffer, channel, index_floor, frac, spacing2),0.0))
        
        return sinc1 + sinc_crossfade * (sinc2 - sinc1)