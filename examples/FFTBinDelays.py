"""PaulStretch is an FFT – based extreme time-stretching algorithm invented by Paul Nasca in 2006. The algorithm works similar to a granular time stretch, but each grain is analyzed by an FFT, the phase is randomized, and then transformed back to the time domain using IFFT. This results in a very smooth and ambient sound when stretching audio to extreme lengths.

This example shows how to use the PaulStretch graph in MMM-Audio to stretch audio in real-time.
You can change the stretch factor by sending different float values to the "dur_mult" parameter.
"""

from mmm_python import *
mmm_audio = MMMAudio(2048, graph_name="FFTBinDelays", package_name="mine")
mmm_audio.start_audio()

def make_delay_times():
    x = 5
    size = 1025
    rand_vals = [rrand(0, 1) for _ in range(x)]
    total = sum(rand_vals)
    normalized = [v / total for v in rand_vals]
    scaled = [round(v * (size / 2.01) + 1) for v in normalized]
    delay_times = []
    for i in range(x):
        rando = int(rrand(0, 200))
        for i2 in range(int(scaled[i])):
            delay_times.append(int(rando))
    return delay_times


delay_times = make_delay_times()
mmm_audio.send_ints("delay_times", delay_times)

mmm_audio.stop_audio()