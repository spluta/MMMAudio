from mmm_audio import *

struct DelaySynth(Representable, Movable, Copyable):
    var world: World

    var buf: Buffer
    var playBuf: Play
    var delays: FB_Delay[2, Interp.lagrange4, True, 1]  # FB_Delay for feedback delay effect - notice we are using ADAA and Oversampling in the internal Tanh funciton.
    var lag: Lag[2]

    fn __init__(out self, world: World):
        self.world = world  
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world) 
        # FB_Delay is initialized as 2 channel
        self.delays = FB_Delay[2, Interp.lagrange4, True, 1](self.world, 1.0) 

        self.lag = Lag[2](self.world, 0.5)  # Initialize Lag with a default time constant


    fn next(mut self) -> SIMD[DType.float64, 2]:

        var sample = self.playBuf.next[num_chans=2,interp=Interp.linear](self.buf, 1.0, True)  # Read samples from the buffer

        # sending one value to the 2 channel lag gives both lags the same parameters
        # var del_time = self.lag.next(linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()), 0.5)

        # this is a version with the 2 value SIMD vector as input each delay with have its own del_time
        var del_time = self.lag.next(
            self.world[].mouse_x * SIMD[DType.float64, 2](1.0, 0.9)
        )

        var feedback = SIMD[DType.float64, 2](self.world[].mouse_y * 2.0, self.world[].mouse_y * 2.1)

        sample = self.delays.next(sample, del_time, feedback)*0.5

        return sample

    fn __repr__(self) -> String:
        return String("DelaySynth")


struct FeedbackDelays(Representable, Movable, Copyable):
    var world: World
    var delay_synth: DelaySynth  # Instance of the Oscillator

    fn __init__(out self, world: World):
        self.world = world
        self.delay_synth = DelaySynth(self.world)  # Initialize the DelaySynth with the world instance

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelays) -> SIMD[DType.float64, 2]:
        return self.delay_synth.next()  # Return the combined output sample