from mmm_audio import *

comptime fftsize: Int = 1024
comptime hopsize: Int = 512
comptime nbands: Int = 10

struct MelBandsTestSuite(FFTProcessable):
    var melbands: MelBands[num_bands=nbands,min_freq=20.0,max_freq=20000.0,fft_size=fftsize]
    var data: List[List[Float64]]

    fn __init__(out self, w: World):
        self.melbands = MelBands[num_bands=nbands,min_freq=20.0,max_freq=20000.0,fft_size=fftsize](w)
        self.data = List[List[Float64]]()

    fn next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64]):
        self.melbands.next_frame(mags, phases)
        self.data.append(self.melbands.bands.copy())

def main():
    w = alloc[MMMWorld](1)
    w.init_pointee_move(MMMWorld(44100.0))
    mbts = MelBandsTestSuite(w)
    fftprocess = FFTProcess[MelBandsTestSuite,fftsize,hopsize,WindowType.hann](w,mbts^)
    buf = Buffer.load("resources/Shiverer.wav")
    for i in range(buf.num_frames):
        _ = fftprocess.next(buf.data[0][i])
    
    print("Number of frames processed: ", len(fftprocess.buffered_process.process.process.data))

    with open("testing/mojo_results/mel_bands_mojo.csv", "w") as f:
        for i,frame in enumerate(fftprocess.buffered_process.process.process.data):
            if i > 0:
                f.write("\n")
            for j,band in enumerate(frame):
                if j > 0:
                    f.write(",")
                f.write(String(band))