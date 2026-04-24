*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# MFCCExample

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.MFCCExample
    options:
      members: []


## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python


from mmm_python import *
ma = MMMAudio(128, graph_name="MFCCExample", package_name="examples")
ma.start_audio()

ma.send_int("update_modulus",80) # higher number = slower updates

ma.stop_audio()

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/MFCCExample.mojo"

```