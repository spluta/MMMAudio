"""
This is the simplest MMMAudio example. It routes input channels directly to output channels.
It also demonstrates how to send a message to the graph to print the current input values to the REPL.
"""

from mmm_python.MMMAudio import *

# this will list available audio devices
list_audio_devices()

# set your own input and output devices here
in_device = "Fireface UCX II (24219339)"
out_device = "Fireface UCX II (24219339)"

# or get some feedback
in_device = "MacBook Pro Microphone"
out_device = "External Headphones"

# instantiate and load the graph
mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=12, in_device=in_device, out_device=out_device, graph_name="In2Out", package_name="examples")
mmm_audio.start_audio()

# print the current sample of inputs to the REPL
mmm_audio.send_trig("print_inputs")  

mmm_audio.stop_audio()

