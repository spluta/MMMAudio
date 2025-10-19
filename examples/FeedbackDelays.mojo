from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Delays import *
from mmm_utils.functions import *
from mmm_utils.Messengers import Messenger
from mmm_utils.functions import dbamp
from mmm_dsp.Filters import SVF

struct DelaySynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    alias maxdelay = 1.0
    var buffer: Buffer
    var playBuf: PlayBuf
    var delays: FBDelay[2, 3]  # FBDelay for feedback delay effect
    var lag: Lag[0.5, 2]
    var mouse_x: Float64
    var mouse_y: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr  
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world_ptr) 
        # FBDelay is initialized as 2 channel
        self.delays = FBDelay[2, 3](self.world_ptr, 1.0) 

        self.lag = Lag[0.5, 2](self.world_ptr)  # Initialize Lag with a default time constant

        self.mouse_x = 0.0
        self.mouse_y = 0.0

    fn next(mut self) -> SIMD[DType.float64, 2]:

        var sample = self.playBuf.next[N=2](self.buffer, 0, 1.0, True)  # Read samples from the buffer

        # sending one value to the 2 channel lag gives both lags the same parameters
        # var del_time = self.lag.next(linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()), 0.5)

        # this is a version with the 2 value SIMD vector as input each delay with have its own del_time
        var del_time = self.lag.next(
            SIMD[DType.float64, 2](
                linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()),
                linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()*0.9)
            )
        )

        var feedback = SIMD[DType.float64, 2](self.mouse_y * 2.0, self.mouse_y * 2.1)

        fb_m = self.m.get_val("feedback", 0.99)
        fb = SIMD[DType.float64, 2](fb_m, fb_m * 0.9)

        delays = self.delays.next(sample, deltime, fb)
        delays = self.svf.lpf(delays, self.m.get_val("ffreq", 8000.0), 0.1)
        sample += delays
        sample *= 0.5
        sample *= self.gate_lag.next(self.m.get_val("gate", 0), 0.03)
        return sample

    fn __repr__(self) -> String:
        return String("DelaySynth")


struct FeedbackDelays(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var delay_synth: DelaySynth  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.delay_synth = DelaySynth(world_ptr)  # Initialize the DelaySynth with the world instance

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelays) -> SIMD[DType.float64, 2]:
        return self.delay_synth.next()  # Return the combined output sample