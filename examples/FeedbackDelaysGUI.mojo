from mmm_audio import *

struct DelaySynth(Representable, Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    comptime maxdelay = 1.0
    var main_lag: Lag
    var buf: Buffer
    var playBuf: Play
    var delays: FB_Delay[num_chans=2, interp=4]  # FB_Delay with 2 channels and interpolation type 3 ()
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

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world  
        self.main_lag = Lag(self.world, 0.03)
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world) 
        self.delays = FB_Delay[num_chans=2, interp=4](self.world, self.maxdelay) 
        self.delay_time_lag = Lag[2](self.world, 0.2)  # Initialize Lag with a default time constant
        self.m = Messenger(self.world)
        self.gate_lag = Lag(self.world, 0.03)
        self.svf = SVF[2](self.world)
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

        var sample = self.playBuf.next[num_chans=2](self.buf, 1 if self.play else 0)  # Read samples from the buffer
        deltime = self.delay_time_lag.next(SIMD[DType.float64, 2](self.delaytime_m, self.delaytime_m * 0.9))


        fb = SIMD[DType.float64, 2](dbamp(self.feedback), dbamp(self.feedback) * 0.9)

        delays = self.delays.next(sample * self.gate_lag.next(1 if self.delay_input else 0), deltime, fb)
        delays = self.svf.lpf(delays, self.ffreq, self.q)
        output = (self.mix * delays) + ((1.0 - self.mix) * sample)
        output *= dbamp(-12.0)
        output *= self.main_lag.next(1 if self.main else 0)
        return output

    fn __repr__(self) -> String:
        return String("DelaySynth")


struct FeedbackDelaysGUI(Representable, Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var delay_synth: DelaySynth  # Instance of the Oscillator

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.delay_synth = DelaySynth(self.world)  # Initialize the DelaySynth with the world instance

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelaysGUI) -> SIMD[DType.float64, 2]:
        return self.delay_synth.next()  # Return the combined output sample