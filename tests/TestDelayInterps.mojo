from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Delays import *
from mmm_dsp.Osc import *
from mmm_utils.Messengers import Messenger
from mmm_dsp.PlayBuf import *

struct TestDelayInterps(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer
    var playBuf: PlayBuf
    var delay_none: Delay[interp=InterpOptions.none]
    var delay_linear: Delay[interp=InterpOptions.linear]
    var delay_cubic: Delay[interp=InterpOptions.cubic]
    var delay_lagrange: Delay[interp=InterpOptions.lagrange4]
    var lag: Lag
    var lfo: Osc
    var m: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.buffer = Buffer("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.world_ptr) 
        self.delay_none = Delay[interp=InterpOptions.none](self.world_ptr,1.0)
        self.delay_linear = Delay[interp=InterpOptions.linear](self.world_ptr,1.0)
        self.delay_cubic = Delay[interp=InterpOptions.cubic](self.world_ptr,1.0)
        self.delay_lagrange = Delay[interp=InterpOptions.lagrange4](self.world_ptr,1.0)
        self.lag = Lag(self.world_ptr, 0.2)
        self.lfo = Osc(self.world_ptr)
        self.m = Messenger(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        var max_delay_time = self.m.get_val("max_delay_time", 0.5)  # Get delay time from messenger, default to 0.5 seconds
        max_delay_time = self.lag.next(max_delay_time)  # Apply lag to the delay time for smooth changes
        lfo_freq = self.m.get_val("lfo_freq",0.5)
        var delay_time = linlin(self.lfo.next(lfo_freq),-1,1,0,max_delay_time)
        var mix = self.m.get_val("mix", 0.5)  # Get mix level from messenger, default to 0.5
        var which_delay = self.m.get_val("which_delay", 0)  # Get which delay type to use from messenger, default to 0 (none)
        
        var sample = self.playBuf.next(self.buffer, 0, 1.0, True)  # Read samples from the buffer
        var delay_none = self.delay_none.next(sample, delay_time)
        var delay_linear = self.delay_linear.next(sample, delay_time)
        var delay_cubic = self.delay_cubic.next(sample, delay_time)
        var delay_lagrange = self.delay_lagrange.next(sample, delay_time)

        var one_delay = select(which_delay,[delay_none,delay_linear,delay_cubic,delay_lagrange])
        var sig = sample * (1.0 - mix) + one_delay * mix  # Mix the dry and wet signals based on the mix level
        var out = SIMD[DType.float64, 2](sig,sig)

        return out