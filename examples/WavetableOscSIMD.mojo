from mmm_audio import *

struct OscVoice(Movable, Copyable):
    var osc: Osc[1,Interp.sinc,0]
    var tri: LFTri[]
    var world: World
    var env: ASREnv
    var gate: Bool
    var freq: Float64
    var wubb_rate: Float64
    var messenger: Messenger

    fn __init__(out self, world: World, name_space: String = ""):
        self.osc = Osc[1,Interp.sinc,0](world)
        self.tri = LFTri(world)
        self.env = ASREnv(world)
        self.gate = False
        self.freq = 440.0
        self.wubb_rate = 0.5
        self.messenger = Messenger(world, name_space)
        self.world = world

    fn next(mut self, ref buffer: SIMDBuffer) -> SIMD[DType.float64, 1]:
        self.messenger.update(self.gate, "gate")
        self.messenger.update(self.freq, "freq")
        self.messenger.update(self.wubb_rate, "wubb_rate")
        osc_frac = self.tri.next(self.wubb_rate, 0.75, trig=self.gate) * 0.5 + 0.5
        return self.osc.next_vwt(buffer, self.freq, osc_frac = osc_frac) * self.env.next(0.01,0.2,0.1,self.gate,2)



struct WavetableOscSIMD(Movable, Copyable):
    comptime wavetables_per_channel = 8

    var world: World  
    var osc_voices: List[OscVoice]
    var buffer: SIMDBuffer[Self.wavetables_per_channel]
    var file_name: String
    var messenger: Messenger
    var filter_cutoff: Float64
    var filter_resonance: Float64
    var moog_filter: VAMoogLadder[1,1]

    fn __init__(out self, world: World):
        self.world = world
        self.file_name = "resources/small_wavetable8.wav"
        
        self.buffer = SIMDBuffer[Self.wavetables_per_channel].load(self.file_name, num_wavetables=self.wavetables_per_channel)
        self.osc_voices = List[OscVoice]()
        for i in range(8):
            self.osc_voices.append(OscVoice(self.world, "voice_"+String(i)))
        
        self.messenger = Messenger(self.world)
        self.filter_cutoff = 20000.0
        self.filter_resonance = 0.5
        self.moog_filter = VAMoogLadder[1,1](self.world)

    fn __repr__(self) -> String:
        return String("Default")

    fn loadBuffer(mut self):
        self.buffer = SIMDBuffer[Self.wavetables_per_channel].load(self.file_name, num_wavetables=self.wavetables_per_channel)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        if self.messenger.notify_update(self.file_name, "load_file"):
            self.loadBuffer()

        var sample = 0.0
        for ref voice in self.osc_voices:
            sample += voice.next(self.buffer)

        self.messenger.update(self.filter_cutoff, "filter_cutoff")
        self.messenger.update(self.filter_resonance, "filter_resonance")
        sample = self.moog_filter.next(sample, self.filter_cutoff, self.filter_resonance)

        return sample * 0.5
