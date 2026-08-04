"""NessStretch is an FFT – based extreme time-stretching algorithm invented by Alex Ness and based on Paul Nasca's PaulStretch algorithm. The algorithm takes the PaulStretch to the extreme, stretching the lowest octave using a 32768 point FFT and the highest octave using a 256 point FFT, resulting in a more detailed sound with better preservation of transients and less smearing.
"""

from mmm_python import *
mmm_audio = MMMAudio(2048, graph_name="NessStretch", package_name="examples")

mmm_audio.send_float("dur_mult", 40.0)

NRT.save_to_wav(mmm_audio, "tmp/nessy.wav", duration_seconds=60)

