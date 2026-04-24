*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# FeedbackDelays

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.FeedbackDelays
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python

from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off
mmm_audio.stop_audio() # stop/pause the audio thread

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/FeedbackDelays.mojo"

```