"""
Demonstrates granular synthesis using TGrains, using a mouse to control granular playback.

Left and right moves around in the buffer. Up and down controls rate of triggers.
"""

from mmmaudio import *
src_mojo = MMMAudio(128, num_output_channels = 8, graph_name="Grains", package_name="examples")
src_mojo.start_audio() # start the audio thread - or restart it where it left off

src_mojo.send_float("max_trig_rate", 80.0) # when trigger creates more than the specified number of overlaps, TGrains will add voices to keep up with the trigger rate. 

src_mojo.stop_audio() # stop/pause the audio thread

src_mojo.plot(20000)