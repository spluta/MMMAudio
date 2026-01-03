from .Filters import lpf_LR4
from .MMMWorld_Module import *

struct Oversampling[num_chans: Int = 1, times_oversampling: Int = 0](Representable, Movable, Copyable):

    var buffer: InlineArray[SIMD[DType.float64, num_chans], times_oversampling]  # Buffer for oversampled values
    var counter: Int64
    var lpf: OS_LPF4[num_chans]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.lpf = OS_LPF4[self.num_chans](world)
        self.buffer = InlineArray[SIMD[DType.float64, num_chans], times_oversampling](fill=SIMD[DType.float64, num_chans](0.0))

        self.counter = 0
        self.lpf.set_sample_rate(world[].sample_rate * times_oversampling)
        
        self.lpf.set_cutoff(0.48 * world[].sample_rate)

    fn __repr__(self) -> String:
        return String("Oversampling")

    fn add_sample(mut self, sample: SIMD[DType.float64, self.num_chans]):
        """Add a sample to the oversampling buffer."""
        self.buffer[self.counter] = sample
        self.counter += 1

    fn get_sample(mut self) -> SIMD[DType.float64, self.num_chans]:
        """get the next sample from a filled oversampling buffer."""
        out = SIMD[DType.float64, self.num_chans](0.0)
        if self.counter > 1:
            for i in range(times_oversampling):
                out = self.lpf.next(self.buffer[i]) # Lowpass filter each sample
        else:
            out = self.buffer[0]
        self.counter = 0
        return out
        
struct Upsampler[num_chans: Int = 1, times_oversampling: Int = 1](Representable, Movable, Copyable):
    var lpf: OS_LPF4[num_chans]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.lpf = OS_LPF4[self.num_chans](world)
        self.lpf.set_sample_rate(world[].sample_rate * times_oversampling)
        self.lpf.set_cutoff(0.5 * world[].sample_rate)

    fn __repr__(self) -> String:
        return String("Upsampler")  

    fn next(mut self, input: SIMD[DType.float64, self.num_chans], i: Int) -> SIMD[DType.float64, self.num_chans]:
        """Process one sample through the upsampler.

        Args:
            input: The input signal to process.
            i: The iterator for the oversampling loop.

        Returns:
            The next sample of the upsampled output.
        """
        if i == 0:
            return self.lpf.next(input) * times_oversampling
        else:
            return self.lpf.next(SIMD[DType.float64, self.num_chans](0.0)) * times_oversampling

struct OS_LPF[num_chans: Int = 1](Movable, Copyable):
    var sample_rate: Float64
    var b0: Float64
    var b1: Float64
    var b2: Float64
    var a1: Float64
    var a2: Float64
    var z1: SIMD[DType.float64, num_chans]
    var z2: SIMD[DType.float64, num_chans]
    alias INV_SQRT2 = 0.7071067811865475

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.sample_rate = world[].sample_rate
        self.b0 = 1.0
        self.b1 = 0.0
        self.b2 = 0.0
        self.a1 = 0.0
        self.a2 = 0.0
        self.z1 = SIMD[DType.float64, num_chans](0.0)
        self.z2 = SIMD[DType.float64, num_chans](0.0)

    fn set_sample_rate(mut self, sr: Float64):
        self.sample_rate = sr

    fn set_cutoff(mut self, fc: Float64):
        var w0 = 2.0 * pi * fc / self.sample_rate
        var cw = cos(w0)
        var sw = sin(w0)
        var Q = self.INV_SQRT2
        var alpha = sw / (2.0 * Q)

        var b0 = (1.0 - cw) * 0.5
        var b1 = 1.0 - cw
        var b2 = (1.0 - cw) * 0.5
        var a0 = 1.0 + alpha
        var a1 = -2.0 * cw
        var a2 = 1.0 - alpha

        # normalize so a0 = 1 (unity DC preserved)
        b0 /= a0
        b1 /= a0
        b2 /= a0
        a1 /= a0
        a2 /= a0

        self.b0 = b0
        self.b1 = b1
        self.b2 = b2
        self.a1 = a1
        self.a2 = a2

    fn next(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        var y = self.b0 * x + self.z1
        self.z1 = self.b1 * x - self.a1 * y + self.z2
        self.z2 = self.b2 * x - self.a2 * y
        return y

struct OS_LPF4[num_chans: Int = 1](Movable, Copyable):
    var os_lpf1: OS_LPF[num_chans]
    var os_lpf2: OS_LPF[num_chans]

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.os_lpf1 = OS_LPF[num_chans](world)
        self.os_lpf2 = OS_LPF[num_chans](world)

    fn set_sample_rate(mut self, sr: Float64):
        self.os_lpf1.set_sample_rate(sr)
        self.os_lpf2.set_sample_rate(sr)
    
    fn set_cutoff(mut self, fc: Float64):
        self.os_lpf1.set_cutoff(fc)
        self.os_lpf2.set_cutoff(fc)

    fn next(mut self, x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
        
        var y = self.os_lpf1.next(x)
        y = self.os_lpf2.next(y)
        return y