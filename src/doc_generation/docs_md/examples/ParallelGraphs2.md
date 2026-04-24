*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# ParallelGraphs2

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.ParallelGraphs2
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")
mmm_audio.start_audio()

mmm_audio2 = MMMAudio(128, graph_name="MoogPops", package_name="examples")
mmm_audio2.start_audio() 

mmm_audio3 = MMMAudio(2048, graph_name="PaulStretch", package_name="examples")
mmm_audio3.start_audio()

mmm_audio.send_int("num_pairs", 30)

mmm_audio3.send_float("dur_mult", 200)

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/ParallelGraphs2.mojo"

```