*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# {{ examplename }}

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.{{examplename}}

## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python

{{code}}

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/{{examplename}}.mojo"

```