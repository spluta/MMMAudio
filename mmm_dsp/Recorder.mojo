from memory import UnsafePointer
from mmm_dsp.Buffer import *
from mmm_src.MMMWorld import *
from .Osc import Impulse
from mmm_utils.functions import *
from .Env import Env

struct Recorder[num_chans: Int = 1](Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var write_head: Int64
    var buf: Buffer

    def __init__(out self, w: UnsafePointer[MMMWorld], num_frames: Int64, sample_rate: Float64):
        self.w = w
        self.write_head = 0
        self.buf = Buffer.zeros(num_frames, num_chans, sample_rate)

    fn __repr__(self) -> String:
        return String("RecordBuf")
    
    # Write SIMD input to buffer
    fn write(mut self, input: SIMD[DType.float64, num_chans], index: Int64):

        if index >= self.buf.num_frames:
            print("Recorder::write: Index out of bounds:", index)

        for chan in range(num_chans):
            self.buf.data[chan][index] = input[chan]

    # write_next SIMD input to buffer at current write head and advance write head
    fn write_next(mut self, value: SIMD[DType.float64, num_chans]):
        self.write_head = (self.write_head + 1) % self.buf.num_frames
        self.write(value, self.write_head)
    
    fn write_previous(mut self, value: SIMD[DType.float64, num_chans]):
        self.write_head = ((self.write_head - 1) + self.buf.num_frames) % self.buf.num_frames
        self.write(value, self.write_head)

    # [TODO]: This is not tested yet
    fn write_next_grow(mut self, input: SIMD[DType.float64, num_chans]):
        if self.write_head + 1 < self.buf.num_frames:
            self.write_head += 1
            self.write(input, self.write_head)
        else:
            for chan in range(num_chans):
                self.buf.data[chan].append(input[chan])
            self.write_head = self.buf.num_frames - 1