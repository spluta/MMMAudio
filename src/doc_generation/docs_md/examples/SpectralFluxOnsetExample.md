*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# SpectralFluxOnsetExample

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.SpectralFluxOnsetExample
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *
ma = MMMAudio(128, graph_name="SpectralFluxOnsetExample", package_name="examples")
ma.start_audio()

# Adjust threshold for onset sensitivity (lower = more sensitive)
ma.send_float("thresh", 67)
# Adjust minimum slice length between onsets (higher = less sensitive)
ma.send_float("minSliceLength", 0.3)  

# Adjust impulse volume
ma.send_float("impulse_vol", 0.5)

ma.stop_audio()

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/SpectralFluxOnsetExample.mojo"

```