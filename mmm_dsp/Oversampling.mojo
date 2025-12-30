from .Filters import lpf_LR4
from mmm_src.MMMWorld import *

struct Oversampling[N: Int = 1, times_oversampling: Int = 0](Representable, Movable, Copyable):

    var buffer: InlineArray[SIMD[DType.float64, N], times_oversampling]  # Buffer for oversampled values
    var counter: Int64
    var lpf: lpf_LR4[N]
    
    var filter_cutoff: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.lpf = lpf_LR4[self.N](world)
        self.buffer = InlineArray[SIMD[DType.float64, N], times_oversampling](fill=SIMD[DType.float64, N](0.0))

        self.counter = 0
        self.lpf.set_sample_rate(self.lpf.svf1.sample_rate * times_oversampling)
        
        self.filter_cutoff = 0.45 * self.lpf.svf1.sample_rate / times_oversampling

    fn __repr__(self) -> String:
        return String("Oversampling")

    fn add_sample(mut self, sample: SIMD[DType.float64, self.N]):
        """Add a sample to the oversampling buffer."""
        self.buffer[self.counter] = sample
        self.counter += 1

    fn get_sample(mut self) -> SIMD[DType.float64, self.N]:
        """get the next sample from a filled oversampling buffer."""
        out = SIMD[DType.float64, self.N](0.0)
        if self.counter > 1:
            for i in range(times_oversampling):
                out = self.lpf.next(self.buffer[i], self.filter_cutoff) # Lowpass filter each sample
        else:
            out = self.buffer[0]
        self.counter = 0
        return out
        
struct Upsampler[N: Int = 1, times_oversampling: Int = 0](Representable, Movable, Copyable):
    var lpf: lpf_LR4[N]
    var filter_cutoff: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.lpf = lpf_LR4[self.N](world)
        self.lpf.set_sample_rate(world[].sample_rate * times_oversampling)
        self.filter_cutoff = 0.49 * world[].sample_rate * times_oversampling

    fn __repr__(self) -> String:
        return String("Upsampler")  

    fn next(mut self, input: SIMD[DType.float64, self.N], i: Int) -> SIMD[DType.float64, self.N]:
        """Process one sample through the upsampler.

        Args:
            input: The input signal to process.
            i: The iterator for the oversampling loop.

        Returns:
            The next sample of the upsampled output.
        """
        if i == 0:
            return self.lpf.next(input*times_oversampling, self.filter_cutoff)
        else:
            return self.lpf.next(SIMD[DType.float64, self.N](0.0), self.filter_cutoff)

