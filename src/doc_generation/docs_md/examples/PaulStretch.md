*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# PaulStretch

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.PaulStretch
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *

mmm_audio = MMMAudio(2048, graph_name="PaulStretch", package_name="examples")
mmm_audio.start_audio()

# change how slow the audio gets stretched
mmm_audio.send_float("dur_mult", 10.0)
mmm_audio.send_float("dur_mult", 100.0)
mmm_audio.send_float("dur_mult", 40.0)
mmm_audio.send_float("dur_mult", 10000.0)

mmm_audio.stop_audio()

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/PaulStretch.mojo"

```