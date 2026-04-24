*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# ManyOscillators

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.ManyOscillators
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")
mmm_audio.start_audio()

mmm_audio.send_int("num_pairs", 2)  # set to 2 pairs of oscillators

mmm_audio.send_int("num_pairs", 14)  # change to 14 pairs of oscillators

mmm_audio.send_int("num_pairs", 300)  # change to 300 pairs of oscillators

mmm_audio.stop_audio() # stop/pause the audio thread

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/ManyOscillators.mojo"

```