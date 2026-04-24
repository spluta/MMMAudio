*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# FFTBinDelays

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.FFTBinDelays
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *
mmm_audio = MMMAudio(2048, graph_name="FFTBinDelays", package_name="examples")
mmm_audio.start_audio()

def make_delay_times():
    x = 5
    size = 1025
    rand_vals = [rrand(0, 1) for _ in range(x)]
    total = sum(rand_vals)
    normalized = [v / total for v in rand_vals]
    scaled = [round(v * (size / 2.01) + 1) for v in normalized]
    delay_times = []
    for i in range(x):
        rando = int(rrand(0, 200))
        for i2 in range(int(scaled[i])):
            delay_times.append(int(rando))
    return delay_times


delay_times = make_delay_times()
mmm_audio.send_ints("delay_times", delay_times)

mmm_audio.stop_audio()

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/FFTBinDelays.mojo"

```