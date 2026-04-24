*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# Grains

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.Grains
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *
mmm_audio = MMMAudio(128, num_output_channels = 8, graph_name="Grains", package_name="examples")
mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.send_float("max_trig_rate", 80.0) # when trigger creates more than the specified number of overlaps, TGrains will add voices to keep up with the trigger rate. 

mmm_audio.stop_audio() # stop/pause the audio thread

mmm_audio.plot(20000)

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/Grains.mojo"

```