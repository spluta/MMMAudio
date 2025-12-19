from mmm_src.MMMWorld import *
from mmm_utils.functions import *

from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messenger import Messenger
from mmm_dsp.Play import *

struct TestDelayInterps(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: Play
    var delay_none: Delay[interp=Interp.none]
    var delay_linear: Delay[interp=Interp.linear]
    var delay_quadratic: Delay[interp=Interp.quad]
    var delay_cubic: Delay[interp=Interp.cubic]
    var delay_lagrange: Delay[interp=Interp.lagrange4]
    var delay_sinc: Delay[interp=Interp.sinc]
    var lag: Lag
    var lfo: Osc
    var m: Messenger
    var mouse_lag: Lag
    var max_delay_time: Float64
    var lfo_freq: Float64
    var mix: Float64
    var which_delay: Float64

    def __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.w) 
        self.delay_none = Delay[interp=Interp.none](self.w,1.0)
        self.delay_linear = Delay[interp=Interp.linear](self.w,1.0)
        self.delay_quadratic = Delay[interp=Interp.quad](self.w,1.0)
        self.delay_cubic = Delay[interp=Interp.cubic](self.w,1.0)
        self.delay_lagrange = Delay[interp=Interp.lagrange4](self.w,1.0)
        self.delay_sinc = Delay[interp=Interp.sinc](self.w,1.0)
        self.lag = Lag(self.w, 0.2)
        self.lfo = Osc(self.w)
        self.m = Messenger(self.w)
        self.mouse_lag = Lag(self.w, 0.05)
        self.max_delay_time = 1.0
        self.lfo_freq = 0.5
        self.mix = 0.5
        self.which_delay = 0.0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        self.m.update(self.max_delay_time,"max_delay_time")  # Get delay time from messenger, default to 0.5 seconds
        # self.max_delay_time = self.lag.next(self.max_delay_time)  # Apply lag to the delay time for smooth changes
        
        self.m.update(self.lfo_freq,"lfo_freq")
        delay_time = linlin(self.lfo.next(self.lfo_freq),-1,1,0,self.max_delay_time)

        dry = self.playBuf.next(self.buffer, 1.0, True)  # Read samples from the buffer
        sample_none = self.delay_none.next(dry, delay_time)
        sample_linear = self.delay_linear.next(dry, delay_time)
        sample_quadratic = self.delay_quadratic.next(dry, delay_time)
        sample_cubic = self.delay_cubic.next(dry, delay_time)
        sample_lagrange = self.delay_lagrange.next(dry, delay_time)
        sample_sinc = self.delay_sinc.next(dry, delay_time)

        self.m.update(self.mix,"mix")  # Get mix level from messenger, default to 0.5
        self.m.update(self.which_delay, "which_delay")  # Get which delay type to use from messenger, default to 0 (none)

        # self.w[].print("max_delay_time: ", self.max_delay_time, " mix: ", self.mix, " which_delay: ", self.which_delay, " delay_time: ", delay_time)

        one_delay = select(self.which_delay,[sample_none,sample_linear,sample_quadratic,sample_cubic,sample_lagrange,sample_sinc])
        sig = dry * (1.0 - self.mix) + one_delay * self.mix  # Mix the dry and wet signals based on the mix level
        
        self.w[].print("dry: ", dry, " one_delay: ", one_delay, " sig: ", sig)

        out = SIMD[DType.float64, 2](dry[0],sig[0])
        return out