from .Filters import lpf_LR4
from mmm_src.MMMWorld import MMMWorld

struct Oversampling(Representable, Movable, Copyable):
    var index: Int  # Oversampling index
    var times_oversampling: Float64  # Size of the oversampling buffer
    var times_os_int: Int64  # Integer version of oversampling factor
    var buffer: InlineArray[Float64, 16]  # Buffer for oversampled values
    var counter: Int64
    var lpf: lpf_LR4
    var filter_cutoff: Float64
    var out: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.buffer = InlineArray[Float64, 16](fill=0.0)
        self.lpf = lpf_LR4(world_ptr)

        self.index = 1
        self.times_oversampling = 2.0 ** Float64(self.index)
        self.times_os_int = Int64(self.times_oversampling)
        self.counter = 0
        self.lpf.set_sample_rate(self.lpf.svf1.sample_rate * self.times_oversampling)
        self.filter_cutoff = 0.45 * self.lpf.svf1.sample_rate / self.times_oversampling
        self.out = 0.0

    fn set_os_index(mut self, index: Int):
        if self.index != index:
            if index < 0:
                self.index = 0
            elif index > 4:
                self.index = 4
            else:
                self.index = index

            self.times_oversampling = 2.0 ** Float64(self.index)
            self.times_os_int = Int64(self.times_oversampling)
            self.counter = 0
            self.lpf.set_sample_rate(self.lpf.svf1.sample_rate * self.times_oversampling)
            self.filter_cutoff = 0.45 * self.lpf.svf1.sample_rate / self.times_oversampling
            self.out = 0.0

    fn __repr__(self) -> String:
        return String("Oversampling")

    fn add_sample(mut self, sample: Float64):
        """Add a sample to the oversampling buffer."""
        self.buffer[self.counter] = sample
        self.counter += 1

    fn get_sample(mut self) -> Float64:
        """get the next sample from a filled oversampling buffer."""
        self.out = 0.0
        if self.counter > 0:
            for i in range(self.times_os_int):
                self.out = self.lpf.next(self.buffer[i], self.filter_cutoff) # Lowpass filter each sample
        else:
            self.out = self.buffer[0]
        self.counter = 0
        return self.out
