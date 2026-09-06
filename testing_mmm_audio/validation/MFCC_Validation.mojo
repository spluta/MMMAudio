from mmm_audio import *

comptime fftsize: Int = 1024
comptime hopsize: Int = 512
comptime num_coeffs: Int = 13
comptime num_bands: Int = 40
comptime min_freq: Float64 = 20.0
comptime max_freq: Float64 = 20000.0

def main() raises:
   
    var buf = Buffer.load("resources/Shiverer.wav")
    var result = MFCC.buf_analysis(buf, chan=0, start_frame=0, num_frames=None, num_coeffs=num_coeffs, num_bands=num_bands, min_freq=min_freq, max_freq=max_freq, window_size=fftsize, hop_size=hopsize, padding=Padding.half_window)
    with open("testing_mmm_audio/validation/mojo_results/mfcc_mojo_results.csv", "w") as f:
        f.write("windowsize," + String(fftsize) + "\n")
        f.write("hopsize," + String(hopsize) + "\n")
        f.write("num_coeffs," + String(num_coeffs) + "\n")
        f.write("num_bands," + String(num_bands) + "\n")
        f.write("min_freq," + String(min_freq) + "\n")
        f.write("max_freq," + String(max_freq) + "\n")
        f.write("Coefficients\n")
        for i, frame in enumerate(result):
            if i > 0:
                f.write("\n")
            for j, coeff in enumerate(frame):
                if j > 0:
                    f.write(",")
                f.write(String(coeff))
