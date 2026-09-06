from mmm_audio import *

comptime fftsize: Int = 1024
comptime hopsize: Int = 512
comptime nbands: Int = 10

def main() raises:

    var buf = Buffer.load("resources/Shiverer.wav")
    var results = MelBands.buf_analysis(buf, chan=0, start_frame=0, num_frames=None, num_bands=nbands, power=2, window_size=fftsize, hop_size=hopsize, padding=Padding.half_window)

    with open("testing_mmm_audio/validation/mojo_results/mel_bands_mojo.csv", "w") as f:
        for i,frame in enumerate(results):
            if i > 0:
                f.write("\n")
            for j,band in enumerate(frame):
                if j > 0:
                    f.write(",")
                f.write(String(band))