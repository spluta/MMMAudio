# Contributing to MMMAudio

Thank you for your interest in contributing to MMMAudio! This guide will help you get started.

## Development Setup

### Prerequisites

- Python 3.9+
- Mojo compiler (latest version)
- Git

### Installation

1. Fork and clone the repository:

```bash
git clone https://github.com/your-username/MMMAudio.git
cd MMMAudio
```

2. Install dependencies:

```bash
pip install -r requirements-docs.txt
```

3. Verify the setup:

```bash
python -c "import mmm_src.MMMAudio; print('Python setup OK')"
mojo --version
```

## Contributing Guidelines

### Code Style

#### Python Code
- Follow PEP 8 style guidelines
- Use type hints for all function signatures
- Use Google-style docstrings
- Maximum line length: 88 characters (Black formatter)

#### Mojo Code
- Follow Mojo style conventions
- Use SIMD types for performance-critical code
- Document all public functions with examples
- Use descriptive variable names

### Documentation

- All public APIs must be documented
- Include practical examples for each function
- Update documentation when changing functionality
- Use the documentation templates in `documentation/`

### Testing

- Add tests for new functionality
- Ensure existing tests pass
- Test both Python and Mojo implementations
- Include performance benchmarks for critical paths

### Pull Request Process

1. Create a feature branch:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. Make your changes with clear, atomic commits

3. Update documentation and tests

4. Generate and review documentation:
   ```bash
   python documentation/generate_docs.py
   mkdocs serve
   ```

5. Submit a pull request with:
   - Clear description of changes
   - Rationale for the changes
   - Any breaking changes noted
   - Screenshots of documentation updates

### Issue Reporting

When reporting issues:
- Use the issue templates
- Include minimal reproduction case
- Specify OS and version information
- Include relevant error messages and logs

## Development Workflow

### Adding New DSP Functions

1. Implement in Mojo for performance (in `mmm_dsp/`)
2. Add comprehensive documentation with examples
3. Create Python wrapper if needed (in `mmm_src/`)
4. Add tests demonstrating functionality
5. Update relevant examples

### Adding New Examples

1. Create example in `examples/` directory
2. Include clear documentation in docstring
3. Ensure example runs without errors
4. Add to examples index in documentation

### Performance Optimization

- Profile before optimizing
- Use SIMD operations where possible
- Benchmark against reference implementations
- Document performance characteristics

## Community

### Communication

- GitHub Issues: Bug reports and feature requests
- Discussions: General questions and community interaction
- Pull Requests: Code contributions and reviews

### Code of Conduct

Please be respectful and constructive in all interactions. We're building a welcoming community for audio developers of all skill levels.

## Release Process

Releases follow semantic versioning:
- Major: Breaking changes
- Minor: New features (backward compatible)
- Patch: Bug fixes

Documentation is automatically built and deployed with each release.