*For more information about the examples, such as how the Python and Mojo files interact with each other, see the [Examples Overview](index.md)*

# {{ example_name }}

<!-- Use mkdocs ":::" syntax to get docstring from Python file -->
:::examples.{{python_file_stem}}

{% if tosc is defined %}
This example has a corresponding [TouchOSC file](https://github.com/spluta/MMMAudio/blob/main/examples/freeverb_example.tosc/{{ tosc }}).
{% endif %}

## Python Code
<!-- Puts the remaining lines from the Python script here -->
```python

{{code}}

```

## Mojo Code
<!-- Put the contents of the .mojo file *of the same name!* here -->
```mojo

--8<-- "examples/{{mojo_file_name}}"

```