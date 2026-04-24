*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# PanAzExample

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.PanAzExample
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


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

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/PanAzExample.mojo"

```