from mmm_src.MMMWorld import *
from mmm_utils.functions import *
from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Delays import *
from mmm_utils.functions import *
from mmm_utils.Messenger import Messenger
from mmm_utils.functions import dbamp
from mmm_dsp.Filters import SVF

struct DelaySynth(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    alias maxdelay = 1.0
    var main_lag: Lag
    var buffer: Buffer
    var playBuf: PlayBuf
    var delays: FB_Delay[N=2, interp=3]  # FB_Delay with 2 channels and interpolation type 3 (cubic)
    var delay_time_lag: Lag[2]
    var m: Messenger
    var gate_lag: Lag[1]
    var svf: SVF[2]
    var play: Bool
    var delaytime_m: Float64
    var feedback: Float64
    var delay_input: Bool
    var ffreq: Float64
    var q: Float64
    var mix: Float64
    var main: Bool

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w  
        self.main_lag = Lag(self.w, 0.03)
        self.buffer = SoundFile.load("resources/Shiverer.wav")
        self.playBuf = PlayBuf(self.w) 
        self.delays = FB_Delay[N=2, interp=3](self.w, self.maxdelay) 
        self.delay_time_lag = Lag[2](self.w, 0.2)  # Initialize Lag with a default time constant
        self.m = Messenger(self.w)
        self.gate_lag = Lag(self.w, 0.03)
        self.svf = SVF[2](self.w)
        self.play = True
        self.delaytime_m = 0.5
        self.feedback = -6.0
        self.delay_input = True
        self.ffreq = 8000.0
        self.q = 1
        self.mix = 0.5
        self.main = True


    fn next(mut self) -> SIMD[DType.float64, 2]:

        self.m.update(self.play,"play")
        self.m.update(self.feedback,"feedback")
        self.m.update(self.delay_input,"delay-input")
        self.m.update(self.ffreq,"ffreq")
        self.m.update(self.delaytime_m,"delay_time")
        self.m.update(self.q,"q")
        self.m.update(self.mix,"mix")
        self.m.update(self.main,"main")

        var sample = self.playBuf.next[N=2](self.buffer, 0, 1 if self.play else 0, True)  # Read samples from the buffer
        deltime = self.delay_time_lag.next(SIMD[DType.float64, 2](self.delaytime_m, self.delaytime_m * 0.9))


        fb = SIMD[DType.float64, 2](dbamp(self.feedback), dbamp(self.feedback) * 0.9)

        delays = self.delays.next(sample * self.gate_lag.next(1 if self.delay_input else 0), deltime, fb)
        delays = self.svf.lpf(delays, self.ffreq, self.q)
        output = (self.mix * delays) + ((1.0 - self.mix) * sample)
        output *= dbamp(-12)
        output *= self.main_lag.next(1 if self.main else 0)
        return output

    fn __repr__(self) -> String:
        return String("DelaySynth")


struct FeedbackDelaysGUI(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var delay_synth: DelaySynth  # Instance of the Oscillator

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.delay_synth = DelaySynth(w)  # Initialize the DelaySynth with the world instance

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelaysGUI) -> SIMD[DType.float64, 2]:
        return self.delay_synth.next()  # Return the combined output sample