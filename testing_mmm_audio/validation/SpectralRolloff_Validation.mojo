"""Spectral Rolloff Unit Test."""

from mmm_audio import *

comptime windowsize: Int = 1024
comptime hopsize: Int = 512

def main() raises:
    var buffer = Buffer.load("resources/Shiverer.wav")
    var results = SpectralRolloff.buf_analysis(buffer, chan=0, start_frame=0, num_frames=None, window_size=windowsize, hop_size=hopsize, padding=Padding.half_window)

    var pth = "testing_mmm_audio/validation/mojo_results/spectral_rolloff_mojo_results.csv"
    try:
        with open(pth, "w") as f:
            f.write("windowsize," + String(windowsize) + "\n")
            f.write("hopsize," + String(hopsize) + "\n")
            f.write("Rolloff\n")
            for i in range(len(results)):
                f.write(String(results[i][0]) + "\n")
        print("Wrote results to ", pth)
    except err:
        print("Error writing to file: ", err)
