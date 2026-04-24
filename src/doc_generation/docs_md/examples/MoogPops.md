*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# MoogPops

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.MoogPops
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python



from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="MoogPops", package_name="examples")
mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.stop_audio() # stop the audio thread
mmm_audio.plot(10000)

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/MoogPops.mojo"

```