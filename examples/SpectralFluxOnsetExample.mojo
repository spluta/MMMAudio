from mmm_audio import *

comptime fft_size: Int = 1024

struct SpectralFluxOnsetsExample(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var playBuf: Play
    var onsets: SpectralFluxOnsets[1]
    var m: Messenger
    var impulse_vol: Float64
    var onsetcounter: Int64

    fn __init__(out self, world: World):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world)
        self.onsets = SpectralFluxOnsets[1](self.world,(fft_size//2) + 1)
        self.onsets.thresh = 67.0
        self.onsets.min_slice_len = 0.3
        self.m = Messenger(self.world)
        self.impulse_vol = 0.5
        self.onsetcounter = 0

    fn next(mut self) -> MFloat[2]:
        
        self.m.update(self.onsets.thresh,"thresh")
        self.m.update(self.impulse_vol,"impulse_vol")
        self.m.update(self.onsets.min_slice_len,"minSliceLength")
        
        # play the audio file
        audio = self.playBuf.next(self.buffer)
        
        # analyze for onsets
        _ = self.onsets.next(audio)
        
        # update threshold

        if self.onsets.state:
            print("onset",self.onsetcounter)
            self.onsetcounter += 1
        
        # generate impulse when onset detected
        impulse = self.impulse_vol if self.onsets.state else 0.0
        
        # left channel: audio, right channel: impulses
        return MFloat[2](audio, impulse)
