

<!-- TRAITS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #9333EA; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Traits
</div>

## trait <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcessable</span>

Implement this trait in a custom struct to pass to `FFTProcess` as a Parameter.

See `TestFFTProcess.mojo` for an example on how to create a spectral process 
using a struct that implements FFTProcessable.



### <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcessable</span> Required Methods

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>



**Signature**

```mojo
next_frame(mut self: _Self, mut complex: List[ComplexSIMD[DType.float64, 1]])
```


**Arguments**

- **complex**: `List`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo_frame</span>



**Signature**

```mojo
next_stereo_frame(mut self: _Self, mut complex: List[ComplexSIMD[DType.float64, 2]])
```


**Arguments**

- **complex**: `List`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_messages</span>



**Signature**

```mojo
get_messages(mut self: _Self)
```




!!! info "Default Implementation"
    This method has a default implementation.

---




<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span>
**Create an FFTProcess for audio manipulation in the frequency domain. This version will output and input complex frequency bins directly rather than magnitude and phase. This is currently untested.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `ComplexFFTProcessable` | — | A user defined struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait. |
| **window_size** | `Int` | `1024` | The size of the FFT window. |
| **hop_size** | `Int` | `512` | The number of samples between each processed spectral frame. |
| **input_window_shape** | `Int` | `WindowType.hann` | Int specifying what window shape to use to modify the amplitude of the input samples before the FFT. See [WindowType](MMMWorld.md/#struct-windowtype) for the options. |
| **output_window_shape** | `Int` | `WindowType.hann` | Int specifying what window shape to use to modify the amplitude of the output samples after the IFFT. See [WindowType](MMMWorld.md/#struct-windowtype) for the options. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initializes a `FFTProcess` struct.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], var process: T)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **process** | `T` | — | A user defined struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized `FFTProcess` struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Processes the next input sample and returns the next output sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: Float64) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `Float64` | — | The next input sample to process. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `Float64`
The next output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span>

<div style="margin-left:3em;" markdown="1">

Processes the next stereo input sample and returns the next output sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span> **Signature**  

```mojo
next_stereo(mut self, input: SIMD[DType.float64, 2]) -> SIMD[DType.float64, 2]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The next input samples to process. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span> **Returns**
: `SIMD`
The next output samples.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span>

<div style="margin-left:3em;" markdown="1">

Returns the next output sample from the internal buffered process. The buffered process reads a block of samples from the provided buffer at the given phase and channel on each hop.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span> **Signature**  

```mojo
next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, chan: Int = 0) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `Buffer` | — | The input buffer to read samples from. |
| **phase** | `Float64` | — | The current phase to read from the buffer. Between 0 (beginning) and 1 (end). |
| **chan** | `Int` | `0` | The channel to read from the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span> **Returns**
: `Float64`
The next output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ComplexFFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span>

<div style="margin-left:3em;" markdown="1">

Returns the next stereo output sample from the internal buffered process. The buffered process reads a block of samples from the provided buffer at the given phase and channel on each hop.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span> **Signature**  

```mojo
next_from_stereo_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> SIMD[DType.float64, 2]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `Buffer` | — | The input buffer to read samples from. |
| **phase** | `Float64` | — | The current phase to read from the buffer. Between 0 (beginning) and 1 (end). |
| **start_chan** | `Int` | `0` | The first channel to read from the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span> **Returns**
: `SIMD`
The next stereo output sample.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
