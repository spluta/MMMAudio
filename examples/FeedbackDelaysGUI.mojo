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
    var main_lag: Lag
    var buffer: Buffer
    var playBuf: PlayBuf
    var delays: FBDelay[N=2, interp=3]  # FBDelay with 2 channels and interpolation type 3 (cubic)
    var delay_time_lag: Lag[2]
    var m: Messenger
    var gate_lag: Lag[1]
    var svf: SVF[2]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr  
        self.main_lag = Lag(self.world_ptr, 0.03)
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world_ptr) 
        self.delays = FBDelay[N=2, interp=3](self.world_ptr, self.maxdelay) 
        self.delay_time_lag = Lag[2](self.world_ptr, 0.2)  # Initialize Lag with a default time constant
        self.m = Messenger(self.world_ptr)
        self.gate_lag = Lag(self.world_ptr, 0.03)
        self.svf = SVF[2](self.world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:

        var sample = self.playBuf.next[N=2](self.buffer, 0, self.m.get_val("play",1), True)  # Read samples from the buffer

        # sending one value to the 2 channel lag gives both lags the same parameters
        # var del_time = self.lag.next(linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()), 0.5)

        # this is a version with the 2 value SIMD vector as input each delay with have its own del_time
        deltime_m = self.m.get_val("delay_time",0.5)
        deltime = self.delay_time_lag.next(SIMD[DType.float64, 2](deltime_m, deltime_m * 0.9))

        fb_m = dbamp(self.m.get_val("feedback", -6))
        fb = SIMD[DType.float64, 2](fb_m, fb_m * 0.9)


        delays = self.delays.next(sample * self.gate_lag.next(self.m.get_val("delay-input", 1)), deltime, fb)
        delays = self.svf.lpf(delays, self.m.get_val("ffreq", 8000.0), self.m.get_val("q", 1.0))
        mix = self.m.get_val("mix", 0.2)
        output = (mix * delays) + ((1.0 - mix) * sample)
        output *= dbamp(-12)
        output *= self.main_lag.next(self.m.get_val("main", 1))
        return output

    fn __repr__(self) -> String:
        return String("DelaySynth")


struct FeedbackDelaysGUI(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var delay_synth: DelaySynth  # Instance of the Oscillator

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.delay_synth = DelaySynth(world_ptr)  # Initialize the DelaySynth with the world instance

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelaysGUI) -> SIMD[DType.float64, 2]:
        return self.delay_synth.next()  # Return the combined output sample