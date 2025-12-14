from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messenger import Messenger
from mmm_dsp.PlayBuf import *

struct TestDelayInterps(Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: PlayBuf
    var delay_none: Delay[interp=DelayInterpOptions.none]
    var delay_linear: Delay[interp=DelayInterpOptions.linear]
    var delay_cubic: Delay[interp=DelayInterpOptions.cubic]
    var delay_lagrange: Delay[interp=DelayInterpOptions.lagrange]
    var lag: Lag
    var lfo: Osc
    var m: Messenger
    var mouse_lag: Lag

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.w) 
        self.delay_none = Delay[interp=DelayInterpOptions.none](self.w,1.0)
        self.delay_linear = Delay[interp=DelayInterpOptions.linear](self.w,1.0)
        self.delay_cubic = Delay[interp=DelayInterpOptions.cubic](self.w,1.0)
        self.delay_lagrange = Delay[interp=DelayInterpOptions.lagrange](self.w,1.0)
        self.lag = Lag(self.w, 0.2)
        self.lfo = Osc(self.w)
        self.m = Messenger(w)
        self.mouse_lag = Lag(self.w, 0.05)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        var max_delay_time = self.m.get_val("max_delay_time", 0.5)  # Get delay time from messenger, default to 0.5 seconds
        max_delay_time = self.lag.next(max_delay_time)  # Apply lag to the delay time for smooth changes
        lfo_freq = self.m.get_val("lfo_freq",0.5)
        var delay_time = linlin(self.lfo.next(lfo_freq),-1,1,0,max_delay_time)
        var mix = self.m.get_val("mix", 0.5)  # Get mix level from messenger, default to 0.5

        var mouse_onoff = self.m.get_val("mouse_onoff", 0)
        delay_time = select(mouse_onoff,[delay_time, self.mouse_lag.next(linlin(self.w[].mouse_x, 0.0, 1.0, 0.0, 0.001))])

        var which_delay = self.m.get_val("which_delay", 0)  # Get which delay type to use from messenger, default to 0 (none)



        
        var sample = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        var delay_none = self.delay_none.next(sample, delay_time)
        var delay_linear = self.delay_linear.next(sample, delay_time)
        var delay_cubic = self.delay_cubic.next(sample, delay_time)
        var delay_lagrange = self.delay_lagrange.next(sample, delay_time)

        var one_delay = select(which_delay,[delay_none,delay_linear,delay_cubic,delay_lagrange])
        var sig = sample * (1.0 - mix) + one_delay * mix  # Mix the dry and wet signals based on the mix level
        var out = SIMD[DType.float64, 2](sample,sig)

        return out