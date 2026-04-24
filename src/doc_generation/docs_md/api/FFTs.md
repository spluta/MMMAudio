

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span>
**Real-valued FFT implementation using Cooley-Tukey algorithm.**

<!-- DESCRIPTION -->
If you're looking to create an FFT-based FX, look to the [FFTProcessable](FFTProcess.md/#trait-fftprocessable)
trait used in conjunction with [FFTProcess](FFTProcess.md/#struct-fftprocess) instead. This struct is a 
lower-level implementation that provides
FFT and inverse FFT on fixed windows of real values. [FFTProcessable](FFTProcess.md/#trait-fftprocessable) structs will enable you to 
send audio samples (such as in a custom struct's `.next()` `fn`) *into* and *out of* 
an FFT, doing some manipulation of the magnitudes and phases in between. ([FFTProcess](FFTProcess.md/#struct-fftprocess)
has this RealFFT struct inside of it.)



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels for SIMD processing. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the RealFFT struct.
All internal buffers and lookup tables are set up here based on the Parameters.
`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, window_size: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **window_size** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft</span>

<div style="margin-left:3em;" markdown="1">

Compute the FFT of the input real-valued samples.
The resulting magnitudes and phases are stored in the internal `mags` and `phases` lists.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft</span> **Signature**  

```mojo
fft(mut self, input: List[SIMD[DType.float64, num_chans]])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `List` | — | The input real-valued samples to transform. This can be a List of SIMD vectors for multi-channel processing or a List of Float64 for single-channel processing. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft</span>

<div style="margin-left:3em;" markdown="1">

Compute the FFT of the input real-valued samples.
The resulting magnitudes and phases are stored in the provided lists.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft</span> **Signature**  

```mojo
fft(mut self, input: List[SIMD[DType.float64, num_chans]], mut mags: List[SIMD[DType.float64, num_chans]], mut phases: List[SIMD[DType.float64, num_chans]])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `List` | — | The input real-valued samples to transform. This can be a List of SIMD vectors for multi-channel processing or a List of Float64 for single-channel processing. |
| **mags** | `List` | — | A mutable list to store the magnitudes of the FFT result. |
| **phases** | `List` | — | A mutable list to store the phases of the FFT result. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ifft</span>

<div style="margin-left:3em;" markdown="1">

Compute the inverse FFT using the internal magnitudes and phases.
The output real-valued samples are written to the provided output list.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ifft</span> **Signature**  

```mojo
ifft(mut self, mut output: List[SIMD[DType.float64, num_chans]])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ifft</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **output** | `List` | — | A mutable list to store the output real-valued samples. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ifft</span>

<div style="margin-left:3em;" markdown="1">

Compute the inverse FFT using the provided magnitudes and phases.
The output real-valued samples are written to the provided output list.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ifft</span> **Signature**  

```mojo
ifft(mut self, mags: List[SIMD[DType.float64, num_chans]], phases: List[SIMD[DType.float64, num_chans]], mut output: List[SIMD[DType.float64, num_chans]])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ifft</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | A list of magnitudes for the inverse FFT. |
| **phases** | `List` | — | A list of phases for the inverse FFT. |
| **output** | `List` | — | A mutable list to store the output real-valued samples. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RealFFT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft_frequencies</span>

<div style="margin-left:3em;" markdown="1">

Compute the FFT bin center frequencies.
This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.fft_frequencies.html).

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft_frequencies</span> **Signature**  

```mojo
fft_frequencies(sr: Float64, n_fft: Int, min_bin: Int = 0, num_bins: Int = -1) -> List[Float64]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft_frequencies</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate of the audio signal. |
| **n_fft** | `Int` | — | The size of the FFT. |
| **min_bin** | `Int` | `0` | The minimum FFT bin index to include. |
| **num_bins** | `Int` | `-1` | The number of FFT bins to include. Defaults to all bins from min_bin to n_fft//2. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">fft_frequencies</span> **Returns**
: `List`
A List of Float64 representing the center frequencies of each FFT bin.
 




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
