*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# MelBandsExample

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.MelBandsExample
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *
ma = MMMAudio(128, graph_name="MelBandsExample", package_name="examples")
ma.start_audio()

ma.send_float("viz_mul",300.0) # 300 is the default in Mojo also
ma.send_float("sines_vol",-26.0) # db
ma.send_float("mix",1.0) 
ma.send_float("mix",0.0)
ma.send_float("mix",0.7)
ma.send_int("update_modulus",80) # higher number = slower updates

ma.stop_audio()

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/MelBandsExample.mojo"

```