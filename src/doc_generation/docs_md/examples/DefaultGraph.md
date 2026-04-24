*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# DefaultGraph

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.DefaultGraph
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="DefaultGraph", package_name="examples")
mmm_audio.start_process()
mmm_audio.start_audio() 

mmm_audio.send_float("pan", 0)

# set the frequency to a random value
from random import random
mmm_audio.send_float("freq", random() * 500 + 100) # set the frequency to a random value

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/DefaultGraph.mojo"

```