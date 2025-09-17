# MMMAudio Documentation

Welcome to the MMMAudio documentation! MMMAudio is a high-performance audio processing library that combines the ease of Python with the speed of Mojo for real-time audio applications.

## Features

- **High Performance**: Leverages Mojo's SIMD capabilities for optimal audio processing
- **Dual Language Support**: Write audio logic in Python, optimize critical paths in Mojo
- **Real-time Capable**: Designed for low-latency audio applications
- **Modular Design**: Composable DSP building blocks
- **ML Integration**: Support for neural network audio processing

## Quick Start

```python
from mmm_src.MMMAudio import MMMAudio
from mmm_dsp.Osc import SineOsc

# Create audio engine
audio = MMMAudio(sample_rate=44100, buffer_size=512)

# Create and connect oscillator
osc = SineOsc(frequency=440.0)
audio.connect(osc, audio.output)

# Start processing
audio.start()
```

## Documentation Structure

- **[Getting Started](getting-started.md)**: Installation and basic usage
- **[API Reference](api/index.md)**: Complete API documentation
- **[Examples](examples/index.md)**: Practical usage examples
- **[Development](development/documentation.md)**: Contributing and development guide

## Architecture

MMMAudio is built around a graph-based processing model where audio flows through connected nodes. Each node can be implemented in either Python (for flexibility) or Mojo (for performance).

### Core Components

- **DSP Modules** (`mmm_dsp`): Basic audio processing building blocks
- **Framework** (`mmm_src`): Audio engine and graph management
- **Utilities** (`mmm_utils`): Mathematical and utility functions

## Community

- **GitHub**: [https://github.com/tedmoore/MMMAudio](https://github.com/tedmoore/MMMAudio)
- **Issues**: Report bugs and feature requests on GitHub