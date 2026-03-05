"""
Shows how to use PanAz to pan audio between multiple speakers arranged in a circle.
You can set the number of speakers between 2 and 8 using the "num_speakers" parameter.
You can set the width of the panning using the "width" parameter.
You can set the frequency of the input tone using the "freq" parameter.

PanAz outputs a SIMD array with one channel per speaker. Since SIMD arrays must be a power of 2 in size, the `num_speakers` parameter must be set to a value below or equal to the size of the SIMD array (8 in this case). Any unused channels will be silent.
"""

from mmm_python import *

# instantiate and load the graph

# PanAz is not quite right as of yet
mmm_audio = MMMAudio(128, graph_name="PanAzExample", package_name="examples", num_output_channels=8)
mmm_audio.start_audio() 

mmm_audio.send_int("num_speakers", 2 ) # set the number of speakers to between 2 and 8

mmm_audio.send_int("num_speakers", 7 ) # set the number of speakers to between 2 and 8
mmm_audio.send_float("width", 1.0 ) # set the width to 1.0 (one speaker at a time)
mmm_audio.send_float("width", 3.0 ) # set the width to 3.0 (extra wide stereo width)

from random import random
mmm_audio.send_float("freq", random() * 500 + 100 ) # set the frequency to a random value