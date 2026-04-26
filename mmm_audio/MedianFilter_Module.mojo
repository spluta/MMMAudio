struct MedianFilter(Movable, Copyable):
    """A simple median filter for scalar samples.

    The window size is forced to be odd and at least 1.
    """
    var size: Int
    var buffer: List[Float64]
    var sorted: List[Float64]
    var index: Int
    var filled_count: Int

    def __init__(out self, size: Int = 5):
        self.size = size
        if self.size < 1:
            self.size = 1
        if (self.size % 2) == 0:
            self.size += 1
        self.buffer = List[Float64](length=self.size, fill=0.0)
        self.sorted = List[Float64](length=self.size, fill=0.0)
        self.index = 0
        self.filled_count = 0

    def process_sample(mut self, value: Float64) -> Float64:
        self.buffer[self.index] = value
        self.index = (self.index + 1) % self.size
        if self.filled_count < self.size:
            self.filled_count += 1

        for i in range(self.filled_count):
            self.sorted[i] = self.buffer[i]

        for i in range(1, self.filled_count):
            var key = self.sorted[i]
            var j = i - 1
            while j >= 0 and self.sorted[j] > key:
                self.sorted[j + 1] = self.sorted[j]
                j -= 1
            self.sorted[j + 1] = key

        return self.sorted[self.filled_count // 2]
