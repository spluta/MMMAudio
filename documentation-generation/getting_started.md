# Getting Started with MMMAudio

MMMAudio is a high-performance audio processing library that combines Python's ease of use with Mojo's performance for real-time audio applications.

## Installation

### Prerequisites

- Python 3.9 or higher
- Mojo compiler (latest version)
- Audio drivers (ASIO on Windows, CoreAudio on macOS, ALSA on Linux)

### Install from Source

1. Clone the repository:

```bash
git clone https://github.com/tedmoore/MMMAudio.git
cd MMMAudio
```

2. Install Python dependencies:

```bash
pip install -r requirements.txt
```

3. Verify Mojo installation:

```bash
mojo --version
```

## Quick Start

### Basic Audio Setup

Create a simple audio processing chain:

```python
from mmm_src.MMMAudio import MMMAudio
from mmm_dsp.Osc import SineOsc

# Initialize audio engine
audio = MMMAudio(
    sample_rate=44100,
    buffer_size=512,
    channels=2
)

# Create a sine wave oscillator
osc = SineOsc(frequency=440.0, amplitude=0.5)

# Connect oscillator to audio output
audio.connect(osc, audio.output)

# Start audio processing
audio.start()

# Let it run for 5 seconds
import time
time.sleep(5)

# Stop audio
audio.stop()
```

### Using Mojo for Performance

For performance-critical operations, use Mojo implementations:

```python
from mmm_utils.functions import linlin
from algorithm import parallelize

# Process control data with SIMD optimization
midi_velocities = [64, 80, 96, 127]  # MIDI velocity values
gains = []

for velocity in midi_velocities:
    # Convert MIDI velocity to linear gain using Mojo function
    gain = linlin(float(velocity), 0.0, 127.0, 0.0, 1.0)
    gains.append(gain)

print(f"Converted gains: {gains}")
```

## Core Concepts

### Audio Graph

MMMAudio uses a graph-based processing model where audio flows through connected nodes:

```python
# Create nodes
input_node = audio.input
osc1 = SineOsc(440.0)
osc2 = SineOsc(880.0)
mixer = Mixer(2)  # 2-input mixer
output_node = audio.output

# Connect the graph
audio.connect(osc1, mixer.input[0])
audio.connect(osc2, mixer.input[1])
audio.connect(mixer, output_node)
```

### SIMD Optimization

Mojo functions support SIMD operations for processing multiple values simultaneously:

```mojo
# Process 4 frequencies at once
from mmm_utils.functions import midicps

midi_notes = SIMD[DType.float64, 4](60.0, 64.0, 67.0, 72.0)  # C major chord
frequencies = midicps[4](midi_notes)  # Convert to frequencies
```

### Real-time Processing

MMMAudio is designed for real-time audio with low latency:

```python
# Configure for low latency
audio = MMMAudio(
    sample_rate=44100,
    buffer_size=128,  # Small buffer for low latency
    channels=2
)

# Use efficient processing chains
reverb = Reverb(room_size=0.5, damping=0.7)
audio.connect(audio.input, reverb)
audio.connect(reverb, audio.output)
```

## Examples

### Simple Synthesizer

```python
from mmm_src.MMMAudio import MMMAudio
from mmm_dsp.Osc import SineOsc
from mmm_dsp.Env import ADSR
from mmm_dsp.Filters import LowPass

# Create audio engine
audio = MMMAudio()

# Create synthesis components
osc = SineOsc(frequency=440.0)
envelope = ADSR(attack=0.1, decay=0.2, sustain=0.7, release=0.5)
filter = LowPass(cutoff=2000.0, resonance=0.5)

# Build signal chain
audio.connect(osc, filter)
audio.connect(envelope, filter.cutoff_mod)  # Envelope modulates filter
audio.connect(filter, audio.output)

# Start synthesis
audio.start()
envelope.trigger()  # Trigger note

time.sleep(2)
envelope.release()  # Release note
time.sleep(1)

audio.stop()
```

### Multi-channel Processing

```python
# Stereo processing with different effects per channel
audio = MMMAudio(channels=2)

# Create stereo sources
osc_left = SineOsc(440.0)
osc_right = SineOsc(442.0)  # Slightly detuned for stereo effect

# Different processing per channel
delay_left = Delay(time=0.3, feedback=0.3)
delay_right = Delay(time=0.4, feedback=0.2)

# Connect stereo processing
audio.connect(osc_left, delay_left)
audio.connect(osc_right, delay_right)
audio.connect(delay_left, audio.output.left)
audio.connect(delay_right, audio.output.right)

audio.start()
```

## Performance Tips

### Use SIMD When Possible

```python
# Instead of processing one value at a time:
for i in range(len(values)):
    result[i] = linlin(values[i], 0.0, 1.0, 20.0, 20000.0)

# Process multiple values with SIMD:
from mmm_utils.functions import linlin

# Convert list to SIMD and process all at once
values_simd = SIMD[DType.float64, 4].from_list(values[:4])
results_simd = linlin[4](values_simd, 0.0, 1.0, 20.0, 20000.0)
```

### Optimize Buffer Sizes

```python
# Balance latency vs CPU usage
audio = MMMAudio(
    buffer_size=256,  # Good balance for most applications
    sample_rate=44100
)

# For very low latency (may increase CPU usage):
audio_low_latency = MMMAudio(buffer_size=64)

# For maximum efficiency (higher latency):
audio_efficient = MMMAudio(buffer_size=1024)
```

### Reuse Objects

```python
# Create objects once and reuse
osc = SineOsc()

# Change parameters instead of creating new objects
osc.set_frequency(880.0)
osc.set_amplitude(0.5)

# This is more efficient than:
# osc = SineOsc(frequency=880.0, amplitude=0.5)  # Creates new object
```

## Troubleshooting

### Audio Dropouts

If you experience audio dropouts:

1. Increase buffer size:
   ```python
   audio = MMMAudio(buffer_size=512)  # or higher
   ```

2. Reduce processing complexity in real-time callbacks

3. Use Mojo implementations for CPU-intensive operations

### Import Errors

Make sure the project is in your Python path:

```python
import sys
sys.path.append('/path/to/MMMAudio')
```

Or install in development mode:

```bash
pip install -e .
```

### Mojo Compilation Issues

Ensure you have the latest Mojo compiler:

```bash
mojo --version
```

Update if necessary according to Mojo documentation.

## Next Steps

- Explore the [API Reference](api/index.md) for detailed function documentation
- Check out [Examples](examples/index.md) for more complex usage patterns
- Read the [Development Guide](development/documentation.md) to contribute

## Community and Support

- **GitHub Issues**: Bug reports and feature requests
- **Discussions**: Questions and community interaction
- **Documentation**: Complete API reference and guides

Happy audio processing with MMMAudio!