from mmm_audio import *

comptime num_bands: Int = 40
comptime num_coeffs: Int = 13
comptime fft_size: Int = 1024

struct MFCCExample(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var playBuf: Play
    var fftproc: FFTProcess[MFCC[num_bands,num_coeffs,fft_size],fft_size,fft_size//2,WindowType.hann]
    var m: Messenger
    var print_counter: Int
    var update_modulus: Int

    fn __init__(out self, world: World):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world)
        p = MFCC[num_bands,num_coeffs,fft_size](self.world)
        self.fftproc = FFTProcess[MFCC[num_bands,num_coeffs,fft_size],fft_size,fft_size//2,WindowType.hann](self.world,p^)
        self.m = Messenger(self.world)
        self.print_counter = 0
        self.update_modulus = 50

    fn next(mut self) -> SIMD[DType.float64, 2]:
        
        self.m.update(self.update_modulus,"update_modulus")
        flute = self.playBuf.next(self.buffer)
        
        # do the analysis
        _ = self.fftproc.next(flute)

        # get the results
        if self.world[].top_of_block:
            # print the mel band energies
            if self.print_counter % self.update_modulus == 0:
                string = "\n\n\n\n\n"
                for i in range(num_coeffs):
                    val = self.fftproc.buffered_process.process.process.coeffs[i]
                    string += "Coeff " + String(i) + ": " + String(val) + "\n"
                
                print(string)
                # print the results
            self.print_counter += 1
        
        return SIMD[DType.float64, 2](flute, flute)