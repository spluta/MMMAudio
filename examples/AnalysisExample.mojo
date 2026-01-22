from mmm_audio import *

struct CustomAnalysis[window_size: Int = 1024](BufferedProcessable):
    var world: LegacyUnsafePointer[MMMWorld]
    var centroid: Float64
    var rms: Float64
    var pitch: Float64
    var pitch_conf: Float64
    var sr: Float64
    var yin: YIN[window_size, 50, 5000]

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.sr = self.world[].sample_rate
        self.centroid = 0.0
        self.pitch = 0.0
        self.pitch_conf = 0.0
        self.rms = 0.0
        self.yin = YIN[window_size, 50, 5000](world)

    fn next_window(mut self, mut frame: List[Float64]):
        self.yin.next_window(frame)
        self.pitch = self.yin.pitch
        self.pitch_conf = self.yin.confidence
        self.rms = RMS.from_window(frame)
        # YIN has to do a special FFT internally no matter what, 
        # so we'll just use the "raw" mags it computes
        # for spectral centroid. It is an FFT with double the frequency resolution
        # (i.e., it's higher resolution, just "interpolated" FFT mags). But it will work just fine here.
        self.centroid = SpectralCentroid.from_mags(self.yin.fft.mags, self.world[].sample_rate)

struct AnalysisExample(Movable, Copyable):
    var world: LegacyUnsafePointer[MMMWorld]
    var osc: Osc[2]
    var buffer: Buffer
    var playBuf: Play
    var freq: Float64
    var analyzer: BufferedInput[CustomAnalysis[1024],1024,512,WindowType.rect]
    var m: Messenger
    var which: Float64

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.osc = Osc[2](self.world)
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world)
        self.analyzer = BufferedInput[CustomAnalysis[1024],1024,512,WindowType.rect](self.world, CustomAnalysis[1024](self.world))
        self.freq = 440.0
        self.m = Messenger(self.world)
        self.which = 0.0

    fn next(mut self) -> SIMD[DType.float64, 2]:
        
        self.m.update(self.freq,"freq")
        self.m.update(self.which,"which")

        oscs = self.osc.next(self.freq,0,False,[OscType.sine, OscType.saw])
        flute = self.playBuf.next(self.buffer)

        sig = select(self.which,[oscs[0], oscs[1], flute])
        
        # do the analysis
        self.analyzer.next(sig)

        # get the results
        (frequency, confidence) = (self.analyzer.process.pitch, self.analyzer.process.pitch_conf)
        rms = self.analyzer.process.rms
        centroid = self.analyzer.process.centroid
        
        # print the results
        self.world[].print("Pitch: ", frequency, " \tHz, Confidence: ", confidence, ", \tRMS: ", rms, ", \tCentroid: ", centroid)
        
        return sig * 0.1
