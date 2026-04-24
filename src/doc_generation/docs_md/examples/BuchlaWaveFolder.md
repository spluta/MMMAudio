*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# BuchlaWaveFolder

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.BuchlaWaveFolder
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="BuchlaWaveFolder_AD", package_name="examples")

# to hear the version without Anti-comptimeing, use:
# mmm_audio = MMMAudio(128, graph_name="BuchlaWaveFolder", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.stop_audio()
mmm_audio.plot(4000)

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/BuchlaWaveFolder.mojo"

```