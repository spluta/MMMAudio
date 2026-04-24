"""NessStretch is an FFT – based extreme time-stretching algorithm invented by Alex Ness and based on Paul Nasca's PaulStretch algorithm. The algorithm takes the PaulStretch to the extreme, stretching the lowest octave using a 32768 point FFT and the highest octave using a 256 point FFT, resulting in a more detailed sound with better preservation of transients and less smearing.
"""
MMMAudio.get_audio_devices()

from srcpy import *
src_mojo = MMMAudio(2048, graph_name="NessStretch", package_name="examples")
src_mojo.start_audio()

# load your own file - the candier pop the better
src_mojo.send_string("file_name", "tmp/Man_short.wav")

# change how slow the audio gets stretched
src_mojo.send_float("dur_mult", 10.0)
src_mojo.send_float("dur_mult", 100.0)
src_mojo.send_float("dur_mult", 40.0)
src_mojo.send_float("dur_mult", 10000.0)

src_mojo.stop_audio()

import numpy as np

np.arange(1024 // 2 + 1)