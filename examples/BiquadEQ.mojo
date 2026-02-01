from mmm_audio import *

struct BiquadEQ(Movable, Copyable):
    """5-band parametric EQ using Biquad filters.
    
    Demonstrates: lowshelf, 3x bell, highshelf
    """
    var world: UnsafePointer[MMMWorld]
    var buf: Buffer
    var play: Play
    var lowshelf: Biquad
    var bell1: Biquad
    var bell2: Biquad
    var bell3: Biquad
    var highshelf: Biquad
    var messenger: Messenger
    
    # EQ parameters
    var ls_freq: Float64
    var ls_gain: Float64
    var b1_freq: Float64
    var b1_gain: Float64
    var b1_q: Float64
    var b2_freq: Float64
    var b2_gain: Float64
    var b2_q: Float64
    var b3_freq: Float64
    var b3_gain: Float64
    var b3_q: Float64
    var hs_freq: Float64
    var hs_gain: Float64
    var playing: Bool

    fn __init__(out self, world: UnsafePointer[MMMWorld]):
        self.world = world
        self.buf = Buffer.load("resources/Shiverer.wav")
        self.play = Play(self.world)
        self.lowshelf = Biquad(self.world)
        self.bell1 = Biquad(self.world)
        self.bell2 = Biquad(self.world)
        self.bell3 = Biquad(self.world)
        self.highshelf = Biquad(self.world)
        self.messenger = Messenger(self.world)
        
        # Default EQ settings (flat response)
        self.ls_freq = 100.0
        self.ls_gain = 0.0
        self.b1_freq = 250.0
        self.b1_gain = 0.0
        self.b1_q = 1.0
        self.b2_freq = 1000.0
        self.b2_gain = 0.0
        self.b2_q = 1.0
        self.b3_freq = 4000.0
        self.b3_gain = 0.0
        self.b3_q = 1.0
        self.hs_freq = 8000.0
        self.hs_gain = 0.0
        self.playing = True

    fn next(mut self) -> SIMD[DType.float64, 2]:
        # Update all parameters from messages
        self.messenger.update(self.playing, "playing")
        self.messenger.update(self.ls_freq, "ls_freq")
        self.messenger.update(self.ls_gain, "ls_gain")
        self.messenger.update(self.b1_freq, "b1_freq")
        self.messenger.update(self.b1_gain, "b1_gain")
        self.messenger.update(self.b1_q, "b1_q")
        self.messenger.update(self.b2_freq, "b2_freq")
        self.messenger.update(self.b2_gain, "b2_gain")
        self.messenger.update(self.b2_q, "b2_q")
        self.messenger.update(self.b3_freq, "b3_freq")
        self.messenger.update(self.b3_gain, "b3_gain")
        self.messenger.update(self.b3_q, "b3_q")
        self.messenger.update(self.hs_freq, "hs_freq")
        self.messenger.update(self.hs_gain, "hs_gain")
        
        # Get stereo sample from buffer
        var sample = self.play.next[num_chans=2](self.buf, 1 if self.playing else 0)
        
        # Process left channel through EQ chain
        var left = sample[0]
        left = self.lowshelf.lowshelf(left, self.ls_freq, 0.7, self.ls_gain)
        left = self.bell1.bell(left, self.b1_freq, self.b1_q, self.b1_gain)
        left = self.bell2.bell(left, self.b2_freq, self.b2_q, self.b2_gain)
        left = self.bell3.bell(left, self.b3_freq, self.b3_q, self.b3_gain)
        left = self.highshelf.highshelf(left, self.hs_freq, 0.7, self.hs_gain)
        
        # For simplicity, duplicate to stereo (or create separate filters for right)
        return SIMD[DType.float64, 2](left, left) * 0.8