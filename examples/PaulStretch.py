"""PaulStretch is an FFT – based extreme time-stretching algorithm invented by Paul Nasca in 2006. The algorithm works similar to a granular time stretch, but each grain is analyzed by an FFT, the phase is randomized, and then transformed back to the time domain using IFFT. This results in a very smooth and ambient sound when stretching audio to extreme lengths.

This example shows how to use the PaulStretch graph in MMM-Audio to stretch audio in real-time.
You can change the stretch factor by sending different float values to the "dur_mult" parameter.
"""

from mmm_python import *

mmm_audio = MMMAudio(2048, graph_name="PaulStretch", package_name="examples")
mmm_audio.start_audio()

# change how slow the audio gets stretched
mmm_audio.send_float("dur_mult", 10.0)
mmm_audio.send_float("dur_mult", 100.0)
mmm_audio.send_float("dur_mult", 40.0)
mmm_audio.send_float("dur_mult", 10000.0)

mmm_audio.stop_audio()