"""
Demonstrates granular synthesis using TGrains, using a mouse to control granular playback.

Left and right moves around in the buffer. Up and down controls rate of triggers.
"""

from mmm_python import *
mmm_audio = MMMAudio(128, num_output_channels = 8, graph_name="Grains", package_name="examples")
mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.stop_audio() # stop/pause the audio thread

mmm_audio.plot(20000)