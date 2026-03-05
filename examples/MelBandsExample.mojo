from mmm_audio import *

comptime num_bands: Int = 100

struct MelBandsExample(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var playBuf: Play
    var analyzer: FFTProcess[MelBands[num_bands,fft_size=1024],1024,512,WindowType.hann]
    var m: Messenger
    var viz_mul: Float64
    var mix: Float64
    var oscs: List[SinOsc[]]
    var freqs: List[Float64]
    var lags: List[Lag[]]
    var sines_vol: Float64
    var print_counter: Int
    var update_modulus: Int

    fn __init__(out self, world: World):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world)
        p = MelBands[num_bands,fft_size=1024](self.world)
        self.analyzer = FFTProcess[MelBands[num_bands,fft_size=1024],1024,512,WindowType.hann](self.world,p^)
        self.m = Messenger(self.world)
        self.viz_mul = 500.0
        self.mix = 1.0
        self.lags = List[Lag[]]()
        self.sines_vol = -18.0
        self.print_counter = 0
        self.update_modulus = 50

        for _ in range(num_bands):
            self.lags.append(Lag(self.world,512.0 / self.world[].sample_rate))

        self.oscs = List[SinOsc[]]()
        for i in range(num_bands):
            self.oscs.append(SinOsc(self.world))

        self.freqs = MelBands.mel_frequencies(num_bands,20.0,20000.0)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        
        self.m.update(self.viz_mul,"viz_mul")
        self.m.update(self.mix,"mix")
        self.m.update(self.sines_vol,"sines_vol")
        self.m.update(self.update_modulus,"update_modulus")
        flute = self.playBuf.next(self.buffer)
        
        # do the analysis
        _ = self.analyzer.next(flute)

        # get the results
        if self.world[].top_of_block:
            # print the mel band energies
            if self.print_counter % self.update_modulus == 0:
                string = "\n\n\n\n\n"
                for i in range(num_bands):
                    idx = num_bands - i - 1
                    val = self.analyzer.buffered_process.process.process.bands[idx]
                    for _ in range(Int(val * self.viz_mul)):
                        string += "*"
                    string += "\n"
                
                print(string)
                # print the results
            self.print_counter += 1
            
        sines = 0.0
        for i in range(num_bands):
            amp = self.lags[i].next(self.analyzer.buffered_process.process.process.bands[i])
            sines += self.oscs[i].next(self.freqs[i]) * amp

        sines *= dbamp(self.sines_vol)

        sig = select(self.mix,[flute,sines])
        
        return sig
