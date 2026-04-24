

<!-- TRAITS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #9333EA; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Traits
</div>

## trait <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcessable</span>

Trait that user structs must implement to be used with a BufferedProcess.

Requires two functions:

- `next_window(buffer: List[Float64]) -> None`: This function is called when enough samples have been buffered.
  The user can process the input buffer in place meaning that the samples you want to return to the output need
  to replace the samples that you receive in the input list.

- `get_messages() -> None`: This function is called at the top of each audio block to allow the user to retrieve any messages
  they may have sent to this process. Put your [Messenger](Messenger.md) message retrieval code here. (e.g. `self.messenger.update(self.param, "param_name")`)



### <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcessable</span> Required Methods

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span>



**Signature**

```mojo
next_window(mut self: _Self, mut samples: List[Float64])
```


**Arguments**

- **samples**: `List`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo_window</span>



**Signature**

```mojo
next_stereo_window(mut self: _Self, mut samples: List[SIMD[DType.float64, 2]])
```


**Arguments**

- **samples**: `List`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcessable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_messages</span>



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



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedInput</span>
**Buffers input samples and hands them over to be processed in 'windows'.**

<!-- DESCRIPTION -->

BufferedInput struct handles buffering of input samples and handing them as "windows" 
to a user defined struct for processing (The user defined struct must implement the 
BufferedProcessable trait). The user defined struct's `next_window()` function is called every
`hop_size` samples. BufferedInput passes the user defined struct a List of `window_size` samples. 
The user can process can do whatever they want with the samples in the List and then must replace the 
values in the List with the values.

<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedInput</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `BufferedProcessable` | — | A user defined struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait. |
| **input_window_shape** | `Int` | `WindowType.hann` | Window shape to apply to the input samples before passing them to the user defined struct. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedInput</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedInput</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initializes a BufferedInput struct.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], var process: T, window_size: Int, hop_size: Int, hop_start: Int = 0)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **process** | `T` | — | A user defined struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait. |
| **window_size** | `Int` | — | The size of the window to process. This will determine how many samples are passed to the user defined struct's `.next_window()` method on each call. |
| **hop_size** | `Int` | — | The number of samples between each processed window. |
| **hop_start** | `Int` | `0` | The initial value of the hop counter. Default is 0. This can be used to offset the processing start time, if for example, you need to offset the start time of the first frame. This can be useful when separating windows into separate `BufferedInput`s, and therefore separate audio streams, so that each window could be routed or processed with different FX chains. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized `BufferedInput` struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedInput</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process the next input sample and return the next output sample.
This function is called in the audio processing loop for each input sample. It buffers the input samples,
and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: Float64)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `Float64` | — | The next input sample to process. |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span>
**Buffers input samples and hands them over to be processed in 'windows'.**

<!-- DESCRIPTION -->

BufferedProcess struct handles buffering of input samples and handing them as "windows" 
to a user defined struct for processing (The user defined struct must implement the 
BufferedProcessable trait). The user defined struct's `next_window()` function is called every
`hop_size` samples. BufferedProcess passes the user defined struct a List of `window_size` samples. 
The user can process can do whatever they want with the samples in the List and then must replace the 
values in the List with the values.

<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `BufferedProcessable` | — | A user defined struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait. |
| **input_window_shape** | `Int` | `WindowType.hann` | Window shape to apply to the input samples before passing them to the user defined struct. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann). |
| **output_window_shape** | `Int` | `WindowType.hann` | Window shape to apply to the output samples after processing by the user defined struct. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initializes a BufferedProcess struct.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], var process: T, window_size: Int, hop_size: Int, hop_start: Int = 0)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **process** | `T` | — | A user defined struct that implements the BufferedProcessable trait. |
| **window_size** | `Int` | — | The size of the window to use for processing. This will determine how many samples are passed to the user defined struct's `.next_window()` method at a time, and also determines the size of the internal buffers. |
| **hop_size** | `Int` | — | The number of samples between each processed window. |
| **hop_start** | `Int` | `0` | The initial value of the hop counter. Default is 0. This can be used to offset the processing start time, if for example, you need to offset the start time of the first frame. This can be useful when separating windows into separate BufferedProcesses, and therefore separate audio streams, so that each window could be routed or processed with different FX chains. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized BufferedProcess struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process the next input sample and return the next output sample.
This function is called in the audio processing loop for each input sample. It buffers the input samples,
and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span>

<div style="margin-left:3em;" markdown="1">

Process the next input sample and return the next output sample.
This function is called in the audio processing loop for each input sample. It buffers the input samples,
and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span> **Signature**  

```mojo
next_stereo(mut self, input: SIMD[DType.float64, 2]) -> SIMD[DType.float64, 2]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The next input sample to process. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_stereo</span> **Returns**
: `SIMD`
The next output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span>

<div style="margin-left:3em;" markdown="1">

Used for non-real-time, buffer-based, processing. At the onset of the next window, reads a block of window_size samples from the provided buffer, starting at the given phase and channel. Phase values between zero and one will read samples within the provided buffer. If the provided phase tries to read samples with an index below zero or above the duration of the buffer, zeros will be returned.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span> **Signature**  

```mojo
next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, chan: Int = 0) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `Buffer` | — | The input buffer to read samples from. |
| **phase** | `Float64` | — | The current phase to start reading from the buffer. |
| **chan** | `Int` | `0` | The channel to read from the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_buffer</span> **Returns**
: `Float64`
The next output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">BufferedProcess</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span>

<div style="margin-left:3em;" markdown="1">

Used for non-real-time, buffer-based, processing of stereo files. At the onset of the next window, reads a window_size block of samples from the provided buffer, starting at the given phase and channel. Phase values between zero and one will read samples within the provided buffer. If the provided phase results in reading samples with an index below zero or above the duration of the buffer, zeros will be returned.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span> **Signature**  

```mojo
next_from_stereo_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> SIMD[DType.float64, 2]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `Buffer` | — | The input buffer to read samples from. |
| **phase** | `Float64` | — | The current phase to read from the buffer. |
| **start_chan** | `Int` | `0` | The first channel to read from the buffer. The second channel will be start_chan + 1. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_from_stereo_buffer</span> **Returns**
: `SIMD`
The next output sample.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
