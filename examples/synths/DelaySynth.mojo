# from mmm_src.MMMWorld import MMMWorld
# from mmm_dsp.Buffer import *
# from mmm_dsp.PlayBuf import *
# from mmm_dsp.Delays import *
# from mmm_dsp.Filters import *
# from mmm_utils.functions import *

# struct DelaySynth(Representable, Movable, Copyable):
#     var world_ptr: UnsafePointer[MMMWorld]

#     var buffer: InterleavedBuffer  # Interleaved buffer for audio samples
#     var playBuf: PlayBuf
#     var delays: List[FBDelay]
#     var lag: Lag
#     var mouse_x: Float64
#     var mouse_y: Float64

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         self.world_ptr = world_ptr  
#         self.buffer = InterleavedBuffer(self.world_ptr, "resources/Shiverer.wav")
#         self.playBuf = PlayBuf(self.world_ptr, self.buffer.num_chans)  # Initialize PlayBuf with the number of channels from the buffer
#         self.delays = List[FBDelay]()  # Initialize Delay with a maximum delay time of 1 second
#         for _ in range(self.buffer.num_chans):
#             self.delays.append(FBDelay(self.world_ptr, 1.0, 0))  # Append FBDelay instances for each channel

#         self.lag = Lag(self.world_ptr)  # Initialize Lag with a default time constant

#         self.mouse_x = 0.0
#         self.mouse_y = 0.0

#     fn next(mut self) -> List[Float64]:
#         self.get_msgs()  # Get messages from the world
#         var sample = self.playBuf.next(self.buffer, 1.0, True)  # Read samples from the buffer

#         var del_time = self.lag.next(linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()), 0.5)

#         for i in range(self.buffer.num_chans):
#             sample[i] = self.delays[i].next(sample[i], del_time, self.mouse_y*2.0, 2)*0.8

#         return sample^

#     fn __repr__(self) -> String:
#         return String("DelaySynth")

#     fn get_msgs(mut self):
#         self.mouse_x = self.world_ptr[0].mouse_x
#         self.mouse_y = self.world_ptr[0].mouse_y