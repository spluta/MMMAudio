

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SIMDBuffer</span>
**A multi-channel audio buffer for storing audio data.**

<!-- DESCRIPTION -->
Audio data is stored in the `data` variable as a `List[MFloat[Self.num_chans]]` where each `MFloat[Self.num_chans]` represents a single frame of audio data for all channels. For example, if `num_chans` is 2, each element of `data` would be an `MFloat[2]` where the first element is the sample value for the left channel and the second element is the sample value for the right channel.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SIMDBuffer</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `2` | — |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SIMDBuffer</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SIMDBuffer</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize a SIMDBuffer with the given audio data and sample rate.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, data: List[SIMD[DType.float64, num_chans]], sample_rate: Float64)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | A `List` of `List`s of `Float64` representing the audio data for each channel. |
| **sample_rate** | `Float64` | — | The sample rate of the audio data. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SIMDBuffer</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span>

<div style="margin-left:3em;" markdown="1">

Initialize a SIMDBuffer with zeros.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span> **Signature**  

```mojo
zeros(num_frames: Int, sample_rate: Float64 = 48000) -> Self
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_frames** | `Int` | — | Number of frames in the buffer. |
| **sample_rate** | `Float64` | `48000` | Sample rate of the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SIMDBuffer</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span>

<div style="margin-left:3em;" markdown="1">

Initialize a SIMDBuffer by loading data from a WAV file using SciPy and NumPy.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span> **Signature**  

```mojo
load(file_name: String, num_wavetables: Int = 1, verbose: Bool = False) -> Self
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | Path to the WAV file to load. |
| **num_wavetables** | `Int` | `1` | Number of wavetables per channel. This is only used if the sound file being loaded contains multiple wavetables concatenated in a single channel. |
| **verbose** | `Bool` | `False` | Whether to print verbose output. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Buffer</span>
**A multi-channel audio buffer for storing audio data.**

<!-- DESCRIPTION -->
Audio data is stored in the `data` variable as a `List[List[Float64]]`, where each inner `List` represents a channel of audio samples.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Buffer</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Buffer</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize a Buffer with the given audio data and sample rate.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, data: List[List[Float64]], sample_rate: Float64)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | A `List` of `List`s of `Float64` representing the audio data for each channel. |
| **sample_rate** | `Float64` | — | The sample rate of the audio data. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Buffer</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span>

<div style="margin-left:3em;" markdown="1">

Initialize a Buffer with zeros.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span> **Signature**  

```mojo
zeros(num_frames: Int, num_chans: Int = 1, sample_rate: Float64 = 48000) -> Self
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_frames** | `Int` | — | Number of frames in the buffer. |
| **num_chans** | `Int` | `1` | Number of channels in the buffer. |
| **sample_rate** | `Float64` | `48000` | Sample rate of the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">zeros</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Buffer</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span>

<div style="margin-left:3em;" markdown="1">

Initialize a Buffer by loading data from a WAV file using SciPy and NumPy.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span> **Signature**  

```mojo
load(file_name: String, num_wavetables: Int = 1, verbose: Bool = False) -> Self
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | Path to the WAV file to load. |
| **num_wavetables** | `Int` | `1` | Number of wavetables per channel. This is only used if the sound file being loaded contains multiple wavetables concatenated in a single channel. |
| **verbose** | `Bool` | `False` | Whether to print verbose output. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">load</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span>
**A collection of static methods for interpolating values from a `List[Float64]` or `InlineArray[Float64]`.**

<!-- DESCRIPTION -->
`SpanInterpolator` supports various interpolation methods including

* no interpolation (none)
* linear interpolation
* quadratic interpolation
* cubic interpolation
* lagrange interpolation (4th order)
* sinc interpolation

The available interpolation methods are defined in the struct [Interp](MMMWorld.md#struct-interp).


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">idx_in_range</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">idx_in_range</span> **Signature**  

```mojo
idx_in_range[num_chans: Int = 1](data: Span[SIMD[DType.float64, num_chans], origin], idx: Int) -> Bool
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">idx_in_range</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">idx_in_range</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | — |
| **idx** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">idx_in_range</span> **Returns**
: `Bool` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a Span[MFloat[num_chans]] using provided index and interpolation method, which is determined at compile time.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Signature**  

```mojo
read[num_chans: Int = 1, interp: Int = Interp.none, bWrap: Bool = True, mask: Int = 0](world: UnsafePointer[MMMWorld, MutExternalOrigin], data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64, prev_f_idx: Float64 = 0) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **interp** | `Int` | `Interp.none` | Interpolation method to use (from [Interp](MMMWorld.md#struct-interp) enum). |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld instance. |
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |
| **prev_f_idx** | `Float64` | `0` | The previous floating-point index (used for [SincInterpolation](SincInterpolator.md)). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a `Span[MFloat[num_chans]]` using provided index with no interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Signature**  

```mojo
read_none[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Signature**  

```mojo
read_none[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](data: Span[SIMD[DType.float64, num_chans], origin], idx: Int) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | — |
| **bWrap** | `Bool` | `True` | — |
| **mask** | `Int` | `0` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | — |
| **idx** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_none</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_linear</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a `Span[MFloat[num_chans]]` using provided index with linear interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_linear</span> **Signature**  

```mojo
read_linear[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_linear</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_linear</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_linear</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_quad</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a `Span[MFloat[num_chans]]` using provided index with quadratic interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_quad</span> **Signature**  

```mojo
read_quad[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_quad</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_quad</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_quad</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_cubic</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a `Span[MFloat[num_chans]]` using provided index with cubic interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_cubic</span> **Signature**  

```mojo
read_cubic[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_cubic</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used. (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_cubic</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_cubic</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_lagrange4</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a `Span[MFloat[num_chans]]` using provided index with lagrange4 interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_lagrange4</span> **Signature**  

```mojo
read_lagrange4[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_lagrange4</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_lagrange4</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_lagrange4</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpanInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_sinc</span>

<div style="margin-left:3em;" markdown="1">

Read a value from a `Span[MFloat[num_chans]]` using provided index with [SincInterpolation](SincInterpolator.md).

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_sinc</span> **Signature**  

```mojo
read_sinc[num_chans: Int = 1, bWrap: Bool = True, mask: Int = 0](world: UnsafePointer[MMMWorld, MutExternalOrigin], data: Span[SIMD[DType.float64, num_chans], origin], f_idx: Float64, prev_f_idx: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_sinc</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels in the data. |
| **bWrap** | `Bool` | `True` | Whether to wrap indices that go out of bounds. |
| **mask** | `Int` | `0` | Bitmask for wrapping indices (if applicable). If 0, standard modulo wrapping is used. If non-zero, bitwise AND wrapping is used (only valid for power-of-two lengths). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_sinc</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld instance. |
| **data** | `Span` | — | The `Span[MFloat[num_chans]]` to read from. |
| **f_idx** | `Float64` | — | The floating-point index to read at. |
| **prev_f_idx** | `Float64` | — | The previous floating-point index. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_sinc</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
