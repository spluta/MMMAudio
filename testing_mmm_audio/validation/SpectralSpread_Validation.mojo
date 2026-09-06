"""Spectral Spread Unit Test."""

from mmm_audio import *

comptime windowsize: Int = 1024
comptime hopsize: Int = 512

def main() raises:
    var buffer = Buffer.load("resources/Shiverer.wav")
    var results = SpectralSpread.buf_analysis(buffer, chan=0, start_frame=0, num_frames=None, window_size=windowsize, hop_size=hopsize, padding=Padding.half_window)

    var pth = "testing_mmm_audio/validation/mojo_results/spectral_spread_mojo_results.csv"
    try:
        with open(pth, "w") as f:
            f.write("windowsize,",windowsize,"\n")
            f.write("hopsize,",hopsize,"\n")
            f.write("Spread\n")
            for i in range(len(results)):
                f.write(String(results[i][0]) + "\n")
        print("Wrote results to ", pth)
    except err:
        print("Error writing to file: ", err)
