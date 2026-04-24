*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# In2Out

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.In2Out
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


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

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/In2Out.mojo"

```