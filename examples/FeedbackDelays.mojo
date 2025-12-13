from mmm_src.MMMWorld import *
from mmm_utils.functions import *


from mmm_dsp.SoundFile import *
from mmm_dsp.Play import *
from mmm_dsp.Delays import *
from mmm_utils.functions import *

struct DelaySynth(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]

    var sf: SoundFile
    var playBuf: Play
    var delays: FB_Delay[2, DelayInterpOptions.lagrange]  # FB_Delay for feedback delay effect
    var lag: Lag[2]
    var mouse_x: Float64
    var mouse_y: Float64

    def __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w  
        self.sf = SoundFile("resources/Shiverer.wav")
        self.playBuf = Play(self.w) 
        # FB_Delay is initialized as 2 channel
        self.delays = FB_Delay[2, DelayInterpOptions.lagrange](self.w, 1.0) 

        self.lag = Lag[2](self.w, 0.5)  # Initialize Lag with a default time constant

        self.mouse_x = 0.0
        self.mouse_y = 0.0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        # grab the mouse position at the start of the block
        if self.w[].top_of_block:
            self.mouse_x = self.w[].mouse_x
            self.mouse_y = self.w[].mouse_y

        var sample = self.playBuf.next[num_chans=2,interp=Interp.linear](self.sf.data, 1.0, True)  # Read samples from the buffer

        # sending one value to the 2 channel lag gives both lags the same parameters
        # var del_time = self.lag.next(linlin(self.mouse_x, 0.0, 1.0, 0.0, self.buffer.get_duration()), 0.5)

        # this is a version with the 2 value SIMD vector as input each delay with have its own del_time
        var del_time = self.lag.next(
            self.mouse_x * SIMD[DType.float64, 2](1.0, 0.9)
        )

        var feedback = SIMD[DType.float64, 2](self.mouse_y * 2.0, self.mouse_y * 2.1)

        sample = self.delays.next(sample, del_time, feedback)*0.5

        return sample

    fn __repr__(self) -> String:
        return String("DelaySynth")


struct FeedbackDelays(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var delay_synth: DelaySynth  # Instance of the Oscillator

    def __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.delay_synth = DelaySynth(w)  # Initialize the DelaySynth with the world instance

    fn __repr__(self) -> String:
        return String("FeedbackDelays")

    fn next(mut self: FeedbackDelays) -> SIMD[DType.float64, 2]:
        return self.delay_synth.next()  # Return the combined output sample