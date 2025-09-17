# Documentation Guide

This guide explains how to write and maintain documentation for MMMAudio.

## Documentation Structure

MMMAudio uses MkDocs with Material theme for documentation generation. The documentation supports both Python and Mojo source files through different processing pipelines.

### Python Documentation

Python files are documented using Google-style docstrings and processed by mkdocstrings:

```python
def example_function(param1: int, param2: str = "default") -> bool:
    \"\"\"Brief description of the function.
    
    Longer description with more details about what the function does,
    its intended use cases, and any important behavior notes.
    
    Args:
        param1: Description of the first parameter.
        param2: Description of the second parameter with default value.
        
    Returns:
        Description of the return value.
        
    Raises:
        ValueError: When param1 is negative.
        
    Examples:
        Basic usage:
        
        ```python
        result = example_function(42, "test")
        ```
        
        With default parameter:
        
        ```python
        result = example_function(42)
        ```
    \"\"\"
    return param1 > 0
```

### Mojo Documentation

Mojo files are documented using triple-quoted docstrings and processed by our custom adapter:

```mojo
fn example_function[N: Int = 1](
    param1: SIMD[DType.int32, N], 
    param2: SIMD[DType.float64, N] = 1.0
) -> SIMD[DType.bool, N]:
    \"\"\"Brief description of the function.
    
    Longer description with details about the function's behavior,
    SIMD optimization, and usage patterns.
    
    Parameters:
        N: SIMD vector width (defaults to 1).
    
    Args:
        param1: Description of the first parameter.
        param2: Description of the second parameter with default.
        
    Returns:
        Description of the return value.
        
    Examples:
        Single value processing:
        
        ```mojo
        result = example_function(42, 1.5)
        ```
        
        Vectorized processing:
        
        ```mojo
        values = SIMD[DType.int32, 4](1, 2, 3, 4)
        factors = SIMD[DType.float64, 4](1.0, 1.5, 2.0, 2.5)
        results = example_function[4](values, factors)
        ```
    \"\"\"
    return param1 > 0
```

## Building Documentation

### Prerequisites

Install documentation dependencies:

```bash
pip install -r requirements-docs.txt
```

### Generate Documentation

Run the documentation pipeline:

```bash
python documentation/generate_docs.py
```

This will:
1. Process all Mojo files and extract documentation
2. Create markdown stubs for Python files
3. Generate example documentation
4. Build the complete documentation site

### Serve Locally

To preview the documentation locally:

```bash
mkdocs serve
```

The documentation will be available at `http://localhost:8000`.

### Build for Production

To build the static documentation site:

```bash
mkdocs build
```

This creates a `site/` directory with the complete documentation.

### Build PDF

To generate a PDF version:

```bash
mkdocs build
# PDF is generated automatically by mkdocs-pdf plugin
```

## Documentation Standards

### Writing Guidelines

1. **Be Clear and Concise**: Use simple, direct language
2. **Include Examples**: Every function should have practical examples
3. **Explain SIMD Usage**: For Mojo functions, explain vectorization benefits
4. **Cross-Reference**: Link to related functions and concepts
5. **Keep Updated**: Update docs when code changes

### Code Examples

- Use real, runnable code examples
- Show both basic and advanced usage
- Include expected output when helpful
- Demonstrate error conditions when relevant

### Function Documentation

Required sections:
- Brief description (first line)
- Detailed description 
- Parameters/Args with types and descriptions
- Returns section
- Examples section

Optional sections:
- Raises (for error conditions)
- Notes (for implementation details)
- See Also (for related functions)

## Maintenance

### Regular Updates

- Review documentation when adding new features
- Update examples to use current best practices
- Check for broken links and outdated information
- Ensure all public APIs are documented

### Documentation Reviews

Include documentation updates in code reviews:
- Verify new functions are documented
- Check that examples are correct and clear
- Ensure docstring formatting is consistent
- Validate that generated docs look correct