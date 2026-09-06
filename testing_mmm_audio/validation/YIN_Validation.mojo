from mmm_audio import *

comptime minfreq: Float64 = 100.0
comptime maxfreq: Float64 = 5000.0
comptime windowsize: Int = 1024
comptime hopsize: Int = 512

def main() raises:

    var buffer = Buffer.load("resources/Shiverer.wav")
    var results = YIN.buf_analysis(buffer, chan=0, start_frame=0, num_frames=None, window_size=windowsize, hop_size=hopsize, min_freq=minfreq, max_freq=maxfreq, padding=Padding.half_window)
    var pth = "testing_mmm_audio/validation/mojo_results/yin_mojo_results.csv"
    try:
        with open(pth, "w") as f:
            f.write("windowsize," + String(windowsize) + "\n")
            f.write("hopsize," + String(hopsize) + "\n")
            f.write("minfreq," + String(minfreq) + "\n")
            f.write("maxfreq," + String(maxfreq) + "\n")
            f.write("Frequency,Confidence\n")
            for i in range(len(results)):
                f.write(String(results[i][0]) + "," + String(results[i][1]) + "\n")
        print("Wrote results to ", pth)
    except err:
        print("Error writing to file: ", err)
