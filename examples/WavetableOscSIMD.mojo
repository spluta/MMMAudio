from mmm_audio import *

struct OscVoice(PolyObject):
    var osc: Osc[1,Interp.sinc,0]
    var tri: LFTri[]
    var world: World
    var env: ASREnv
    var gate: Bool
    var freq: Float64
    var vol: Float64
    var wubb_rate: Float64
    var messenger: Messenger
    var triggered: Bool

    fn check_active(mut self) -> Bool:
        return self.env.is_active

    fn make_inactive(mut self):
        self.env.is_active = False
    
    # Poly will use this function to release the voice when it receives a note off message for the note that this voice is playing. 
    fn set_gate(mut self, gate: Bool):
        self.gate = gate

    fn __init__(out self, world: World, name_space: String = ""):
        self.osc = Osc[1,Interp.sinc,0](world)
        self.tri = LFTri(world)
        self.env = ASREnv(world)
        self.gate = False
        self.freq = 440.0
        self.vol = 1.0
        self.wubb_rate = 0.5
        self.messenger = Messenger(world, name_space)
        self.world = world
        self.triggered = False

    fn next(mut self, ref buffer: SIMDBuffer) -> MFloat[1]:
        osc_frac = self.tri.next(self.wubb_rate, 0.75, trig=self.gate) * 0.5 + 0.5
        return self.osc.next_vwt(buffer, self.freq, osc_frac = osc_frac) * self.env.next(0.01,0.2,0.1,self.gate,2) * self.vol

struct WavetableOscSIMD(Movable, Copyable):
    comptime wavetables_per_channel = 8
    comptime num_messages = 10

    var world: World  
    var voices: List[OscVoice]
    var buffer: SIMDBuffer[Self.wavetables_per_channel]
    var file_name: String
    var messenger: Messenger
    var filter_cutoff: Float64
    var filter_resonance: Float64
    var moog_filter: VAMoogLadder[1,1]
    var poly: Poly[]

    fn __init__(out self, world: World):
        self.world = world
        self.file_name = "resources/small_wavetable8.wav"
        
        self.buffer = SIMDBuffer[Self.wavetables_per_channel].load(self.file_name, num_wavetables=self.wavetables_per_channel)
        self.voices = [OscVoice(self.world, "voice_"+String(i)) for i in range(8)]
        
        self.messenger = Messenger(world)
        self.filter_cutoff = 20000.0
        self.filter_resonance = 0.5
        self.moog_filter = VAMoogLadder[1,1](self.world)
        self.poly = Poly(8, 64, world)

    fn __repr__(self) -> String:
        return String("Default")

    fn loadBuffer(mut self):
        self.buffer = SIMDBuffer[Self.wavetables_per_channel].load(self.file_name, num_wavetables=self.wavetables_per_channel)

    fn next(mut self) -> MFloat[2]:
        if self.messenger.notify_update(self.file_name, "load_file"):
            self.loadBuffer()

        var out = 0.0

        self.poly.reset(self.voices) # reset the triggered state of all voices at the beginning of each block

        # can receive up to num_messages each audio block
        for i in range(Self.num_messages):
            note = [0, 0]
            trig = self.messenger.notify_update(note, "note"+String(i))

            # if we received a trig, find and play a free voice
            if trig:
                if note[1] > 0: # if the velocity is greater than 0, trigger the note on
                    print(note[0], note[1])
                    free_voice = self.poly.find_free_voice_and_open(self.voices, trig, Int(note[0])) # get the index of the free voice
                    
                    self.voices[free_voice].freq = midicps(Float64(note[0]))
                    self.voices[free_voice].vol = note[1] / 127.0
                else: # if the velocity is 0, trigger the note off for that note
                    # close the gate for the voice that is playing and forget that is was playing
                    self.poly.close_voice(self.voices, Int(note[0])) 
        
        # add the output of all the voices that were not triggered
        for ref voice in self.voices:
            out += voice.next(self.buffer)

        self.messenger.update(self.filter_cutoff, "filter_cutoff")
        self.messenger.update(self.filter_resonance, "filter_resonance")
        wubb_rate = 0.0
        got_wubbed = self.messenger.notify_update(wubb_rate, "wubb_rate")
        if got_wubbed:
            for ref voice in self.voices:
                voice.wubb_rate = wubb_rate
        sample = self.moog_filter.next(out, self.filter_cutoff, self.filter_resonance)

        return sample * 0.5
