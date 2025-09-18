# API Reference

This section contains the complete API reference for MMMAudio, organized by module.

## Core DSP (`mmm_dsp`)

The core DSP modules provide the fundamental building blocks for audio processing:

- **[Utilities](mmm_utils/functions.md)**: Mathematical utility functions
- **[Oscillators](mmm_dsp/Osc.md)**: Sine, square, sawtooth, and noise generators
- **[Filters](mmm_dsp/Filters.md)**: Low-pass, high-pass, band-pass filters
- **[Envelopes](mmm_dsp/Env.md)**: ADSR and other envelope generators
- **[Delays](mmm_dsp/Delays.md)**: Delay lines and echo effects
- **[Buffers](mmm_dsp/Buffer.md)**: Audio buffer management
- **[Effects](mmm_dsp/Distortion.md)**: Distortion and saturation

## Framework (`mmm_src`)

The framework modules handle audio engine management and processing:

- **[Audio Engine](mmm_src/MMMAudio.md)**: Main audio processing engine
- **[Graph System](mmm_src/MMMGraphs.md)**: Audio graph management
- **[Traits](mmm_src/MMMTraits.md)**: Core interfaces and traits
- **[Scheduler](mmm_src/Scheduler.md)**: Event scheduling and timing

## Utilities (`mmm_utils`)

Utility modules provide mathematical functions and helpers:

- **[Functions](mmm_utils/functions.md)**: Mathematical utility functions
- **[FFT](mmm_utils/MMM_FFT.md)**: Fast Fourier Transform utilities
- **[Windows](mmm_utils/Windows.md)**: Window functions for DSP

## Documentation Conventions

### Function Signatures

Functions are documented with their complete signatures including type information:

```mojo
fn linlin[N: Int = 1](
    value: SIMD[DType.float64, N], 
    in_min: SIMD[DType.float64, N], 
    in_max: SIMD[DType.float64, N], 
    out_min: SIMD[DType.float64, N], 
    out_max: SIMD[DType.float64, N]
) -> SIMD[DType.float64, N]
```

### SIMD Support

Most functions support SIMD operations for processing multiple values simultaneously. The `N` parameter controls the SIMD width.

### Examples

Each function includes practical examples showing typical usage patterns.