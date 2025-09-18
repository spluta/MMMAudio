# in2out

:::examples.in2out

```python


from mmm_src.MMMAudio import *

# this will list available audio devices
list_audio_devices()

in_device = "Fireface UFX+ (24059506)"
out_device = "Fireface UFX+ (24059506)"

# or get some feedback
in_device = "MacBook Pro Microphone"
out_device = "External Headphones"

# instantiate and load the graph
mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=12, in_device=in_device, out_device=out_device, graph_name="In2Out", package_name="examples")
mmm_audio.start_audio()

# print the current sample of inputs to the REPL
mmm_audio.send_msg("print_inputs")  

mmm_audio.stop_audio()

```