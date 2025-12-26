from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messenger import Messenger
from mmm_dsp.PlayBuf import *

struct TestDelayInterps(Movable, Copyable):
    var world: UnsafePointer[MMMWorld]
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
    var max_delay_time: Float64
    var lfo_freq: Float64
    var mix: Float64
    var which_delay: Float64
    var mouse_onoff: Float64





    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world) 
        self.delay_none = Delay[interp=DelayInterpOptions.none](self.world,1.0)
        self.delay_linear = Delay[interp=DelayInterpOptions.linear](self.world,1.0)
        self.delay_cubic = Delay[interp=DelayInterpOptions.cubic](self.world,1.0)
        self.delay_lagrange = Delay[interp=DelayInterpOptions.lagrange](self.world,1.0)
        self.lag = Lag(self.world, 0.2)
        self.lfo = Osc(self.world)
        self.m = Messenger(world)
        self.mouse_lag = Lag(self.world, 0.05)
        self.max_delay_time = 0.5
        self.lfo_freq = 0.5
        self.mix = 0.5
        self.which_delay = 0
        self.mouse_onoff = 0



    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update(self.max_delay_time,"max_delay_time")  # Get delay time from messenger, default to 0.5 seconds
        # self.max_delay_time = self.lag.next(self.max_delay_time)  # Apply lag to the delay time for smooth changes
        
        self.m.update(self.lfo_freq,"lfo_freq")

        delay_time = linlin(self.lfo.next(self.lfo_freq),-1,1,0.001,self.max_delay_time)

        self.m.update(self.mix,"mix")


        self.m.update(self.mouse_onoff, "mouse_onoff")
        delay_time = select(self.mouse_onoff,[delay_time, self.mouse_lag.next(linlin(self.world[].mouse_x, 0.0, 1.0, 0.0, 0.001))])

        self.m.update(self.which_delay, "which_delay")

        
        var sample = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        var delay_none = self.delay_none.next(sample, delay_time)
        var delay_linear = self.delay_linear.next(sample, delay_time)
        var delay_cubic = self.delay_cubic.next(sample, delay_time)
        var delay_lagrange = self.delay_lagrange.next(sample, delay_time)

        var one_delay = select(self.which_delay,[delay_none,delay_linear,delay_cubic,delay_lagrange])
        var sig = sample * (1.0 - self.mix) + one_delay * self.mix  # Mix the dry and wet signals based on the mix level
        var out = SIMD[DType.float64, 2](sample,sig)

        return out