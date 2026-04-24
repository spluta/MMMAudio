

<!-- TRAITS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #9333EA; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Traits
</div>

## trait <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcessable</span>

Implement this trait in a custom struct to pass to `FFTProcess` as a Parameter.

See `TestFFTProcess.mojo` for an example on how to create a spectral process 
using a struct that implements FFTProcessable.

This trait requires that two functions be implemented (see below for more details).

* `fn next_frame()`: This function gets passed a list of magnitudes
and a list of phases that are the result of an FFT. The user should manipulate 
these values in place so that once this function is done the values in those 
lists are what the user wants to be used for the IFFT conversion back into 
amplitude samples. Because the FFT only happens every `hop_size` samples (and
uses the most recent `window_size` samples), this function only gets called every
`hop_size` samples. `hop_size` is set as a parameter in the `FFTProcessor`
struct that the user's struct is passed to.
* `fn get_messages()`: Because `.next_frame()` only runs every `hop_size`
samples and a `Messenger` can only check for new messages from Python at the top 
of every audio block, it's not guaranteed that these will line up, so this struct
could very well miss incoming messages! To remedy this, put all your message getting
code in this get_messages() function. It will get called by FFTProcessor (whose 
`.next()` function does get called every sample) to make sure that any messages
intended for this struct get updated.

## Outline of Spectral Processing:

1. The user creates a custom struct that implements the FFTProcessable trait. The
required functions for that are `.next_frame()` and `.get_messages()`. 
`.next_frame()` is passed a `List[Float64]` of magnitudes and a
`List[Float64]` of phases. The user can manipulate this data however they want and 
then needs to replace the values in those lists with what they want to be used for
the IFFT.
2. The user passes their struct (in 1) as a Parameter to the `FFTProcess` struct. 
You can see where the parameters such as `window_size`, `hop_size`, and window types 
are expressed.
3. In the user synth's `.next()` function (running one sample at a time) they pass in
every sample to the `FFTProcess`'s `.next()` function which:
    * has a `BufferedProcess` to store samples and pass them on 
    to `FFTProcessor` when appropriate
    * when `FFTProcessor` receives a window of amplitude samples, it performs an
    `FFT` getting the mags and phases which are then passed on to the user's 
    struct that implements `FFTProcessable`. The mags and phases are modified in place
    and then this whole pipeline basically hands the data all the way back out to the user's
    synth struct where `FFTProcess`'s `.next()` function returns the next appropriate
    sample (after buffering -> FFT -> processing -> IFFT -> output buffering) to get out 
    to the speakers (or whatever).


### <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcessable</span> Required Methods

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>



**Signature**

```mojo
next_frame(mut self: _Self, mut magnitudes: List[Float64], mut phases: List[Float64])
```


**Arguments**

- **magnitudes**: `List`- **phases**: `List`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo_frame</span>



**Signature**

```mojo
next_stereo_frame(mut self: _Self, mut magnitudes: List[SIMD[DType.float64, 2]], mut phases: List[SIMD[DType.float64, 2]])
```


**Arguments**

- **magnitudes**: `List`- **phases**: `List`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_messages</span>



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



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span>
**Create an FFTProcess for audio manipulation in the frequency domain.**

<!-- DESCRIPTION -->

FFTProcess is similar to BufferedProcess, but instead of passing time domain samples to the user defined struct,
it passes frequency domain magnitudes and phases (obtained from an FFT). The user defined struct must implement
the FFTProcessable trait, which requires the implementation of the `.next_frame()` function. This function
receives two Lists: one for magnitudes and one for phases. The user can do whatever they want with the values in these Lists,
and then must replace the values in the Lists with the values they want to be used for the IFFT to convert the information
back to amplitude samples.

<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `FFTProcessable` | — | A user defined struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait. |
| **input_window_shape** | `Int` | `WindowType.hann` | Int specifying what window shape to use to modify the amplitude of the input samples before the FFT. See [WindowType](MMMWorld.md/#struct-windowtype) for the options. |
| **output_window_shape** | `Int` | `WindowType.hann` | Int specifying what window shape to use to modify the amplitude of the output samples after the IFFT. See [WindowType](MMMWorld.md/#struct-windowtype) for the options. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initializes a `FFTProcess` struct.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], var process: T, window_size: Int, hop_size: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **process** | `T` | — | A user defined struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait. |
| **window_size** | `Int` | — | The size of the window to use for processing. This will determine how many samples are passed to the user defined struct's `.next_window()` method. |
| **hop_size** | `Int` | — | The number of samples between the beginning of FFT windows. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized `FFTProcess` struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span>

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span>

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FFTProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span>

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
