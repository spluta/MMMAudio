from mmm_audio import *

struct BufSynth(Movable, Copyable):
    var world: World
    var buffer: Buffer

    var num_chans: Int64

    var play_buf: Play
    var play_rate: Float64
    
    var moog: VAMoogLadder[2, 1] # 2 channels, os_index == 1 (2x oversampling)
    var lpf_freq: Float64
    var lpf_freq_lag: Lag[]
    var messenger: Messenger

    fn __init__(out self, world: World):
        self.world = world 
        print("world memory location:", world)

        # load the audio buffer 
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        # without printing this, the compiler wants to free the buffer for some reason
        print("Loaded buffer with", self.buffer.num_chans, "channels and", self.buffer.num_frames, "frames.")

        self.play_rate = 1.0

        self.play_buf = Play(self.world)

        self.moog = VAMoogLadder[2, 1](self.world)
        self.lpf_freq = 20000.0
        self.lpf_freq_lag = Lag(self.world, 0.1)

        self.messenger = Messenger(self.world)

    fn next(mut self) -> MFloat[2]:
        self.messenger.update(self.lpf_freq, "lpf_freq")
        self.messenger.update(self.play_rate, "play_rate")

        out = self.play_buf.next[num_chans=2](self.buffer, self.play_rate, True)

        freq = self.lpf_freq_lag.next(self.lpf_freq)
        out = self.moog.next(out, freq, 1.0)
        return out

struct PlayExample(Movable, Copyable):
    var world: World

    var buf_synth: BufSynth  # Instance of the BufSynth

    fn __init__(out self, world: World):
        self.world = world

        self.buf_synth = BufSynth(self.world)  

    fn next(mut self) -> MFloat[2]:
        return self.buf_synth.next()  # Return the combined output sample
