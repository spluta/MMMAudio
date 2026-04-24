

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span>
**A lag processor that smooths input values over time based on a specified lag time in seconds.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of SIMD channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the lag processor with given lag time in seconds.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], lag: SIMD[DType.float64, num_chans] = 0.02)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |
| **lag** | `SIMD` | `0.02` | SIMD vector specifying lag time in seconds for each channel. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the lag processor.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, in_samp: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **in_samp** | `SIMD` | — | Input SIMD vector values. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
Output values after applying the lag.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_lag_time</span>

<div style="margin-left:3em;" markdown="1">

Set a new lag time in seconds for each channel.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_lag_time</span> **Signature**  

```mojo
set_lag_time(mut self, lag: SIMD[DType.float64, num_chans])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_lag_time</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **lag** | `SIMD` | — | SIMD vector specifying new lag time in seconds for each channel. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Lag</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">par_process</span>

<div style="margin-left:3em;" markdown="1">

Parallel processes a List[Lag[simd_width]]. The one dimensional list of vals is both the input and the output.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">par_process</span> **Signature**  

```mojo
par_process[num_simd: Int, simd_width: Int](mut lags: List[Lag[simd_width]], mut vals: List[Float64])
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">par_process</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_simd** | `Int` | — | — |
| **simd_width** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">par_process</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **lags** | `List` | — | — |
| **vals** | `List` | — | — |





<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span>
**A State Variable Filter struct.**

<!-- DESCRIPTION -->
To use the different modes, see the mode-specific methods.

Implementation from [Andrew Simper](https://cytomic.com/files/dsp/SvfLinearTrapOptimised2.pdf). 
Translated from Oleg Nesterov's Faust implementation.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of SIMD channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the SVF.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">reset</span>

<div style="margin-left:3em;" markdown="1">

Clears any leftover internal state so the filter starts clean after interruptions or discontinuities in the audio stream.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">reset</span> **Signature**  

```mojo
reset(mut self)
```







<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF lowpass filter. Passes frequencies below the cutoff while attenuating frequencies above it.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Signature**  

```mojo
lpf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency of the lowpass filter. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF bandpass filter. Passes a band of frequencies centered at the cutoff while attenuating frequencies above and below.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Signature**  

```mojo
bpf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The center frequency of the bandpass filter. |
| **q** | `SIMD` | — | The bandwidth of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF highpass filter. Passes frequencies above the cutoff while attenuating frequencies below it.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Signature**  

```mojo
hpf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency of the highpass filter. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">peak</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF peak filter. Boosts or cuts a band of frequencies centered at the cutoff by an amount determined by q, leaving frequencies outside the band unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">peak</span> **Signature**  

```mojo
peak(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">peak</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The center frequency of the peak filter. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">peak</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF notch (band stop) filter. Attenuates a narrow band of frequencies centered at the cutoff while passing all others.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span> **Signature**  

```mojo
notch(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The center frequency of the notch filter. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF allpass filter. Passes all frequencies at equal amplitude while shifting their phase relationship around the cutoff frequency.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span> **Signature**  

```mojo
allpass(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The center frequency of the allpass filter. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF bell (peaking EQ) filter. Boosts or cuts a band of frequencies centered at the cutoff by a specified gain amount, leaving frequencies outside the band unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span> **Signature**  

```mojo
bell(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain_db: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The center frequency of the bell filter. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain_db** | `SIMD` | — | The amount to boost/cut around the cutoff. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF lowshelf filter. Boosts or cuts all frequencies below the cutoff by a specified gain amount, leaving frequencies above unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span> **Signature**  

```mojo
lowshelf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain_db: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency of the low shelf filter. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain_db** | `SIMD` | — | The amount to boost/cut around the cutoff. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SVF</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a SVF highshelf filter. Boosts or cuts all frequencies above the cutoff by a specified gain amount, leaving frequencies below unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span> **Signature**  

```mojo
highshelf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain_db: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency of the high shelf filter. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain_db** | `SIMD` | — | The amount to boost/cut around the cutoff. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf_LR4</span>
**A 4th-order [Linkwitz-Riley](https://en.wikipedia.org/wiki/Linkwitz%E2%80%93Riley_filter) lowpass filter.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf_LR4</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of SIMD channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf_LR4</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf_LR4</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the 4th-order Linkwitz-Riley lowpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf_LR4</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

A single sample through the 4th order Linkwitz-Riley lowpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **frequency** | `SIMD` | — | The cutoff frequency of the lowpass filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OnePole</span>
**One-pole IIR filter that can be configured as lowpass or highpass.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OnePole</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OnePole</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OnePole</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the one-pole filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OnePole</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the one-pole lowpass filter with a given cutoff frequency.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Signature**  

```mojo
lpf(mut self, input: SIMD[DType.float64, num_chans], cutoff_hz: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **cutoff_hz** | `SIMD` | — | The cutoff frequency of the lowpass filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OnePole</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the one-pole highpass filter with a given cutoff frequency.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Signature**  

```mojo
hpf(mut self, input: SIMD[DType.float64, num_chans], cutoff_hz: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **cutoff_hz** | `SIMD` | — | The cutoff frequency of the highpass filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCTrap</span>
**DC Trap filter.**

<!-- DESCRIPTION -->
Implementation from Digital Sound Generation by Beat Frei. The cutoff
frequency of the highpass filter is fixed to 5 Hz.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCTrap</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCTrap</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCTrap</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the DC blocker filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCTrap</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the DC blocker filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAOnePole</span>
**One-pole filter based on the Virtual Analog design by  Vadim Zavalishin in "The Art of VA Filter Design".**

<!-- DESCRIPTION -->
This implementation supports both lowpass and highpass modes.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAOnePole</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAOnePole</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAOnePole</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the VAOnePole filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAOnePole</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the VA one-pole lowpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Signature**  

```mojo
lpf(mut self, input: SIMD[DType.float64, num_chans], freq: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **freq** | `SIMD` | — | The cutoff frequency of the lowpass filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAOnePole</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the VA one-pole highpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Signature**  

```mojo
hpf(mut self, input: SIMD[DType.float64, num_chans], freq: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **freq** | `SIMD` | — | The cutoff frequency of the highpass filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAMoogLadder</span>
**Virtual Analog Moog Ladder Filter.**

<!-- DESCRIPTION -->
Implementation based on the Virtual Analog design by Vadim Zavalishin in 
"The Art of VA Filter Design"

This implementation supports 4-pole lowpass filtering with optional [oversampling](Oversampling.md).



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAMoogLadder</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels to process in parallel. |
| **os_index** | `Int` | `0` | [oversampling](Oversampling.md) factor as a power of two (0 = no oversampling, 1 = 2x, 2 = 4x, etc). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAMoogLadder</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAMoogLadder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the VAMoogLadder filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">VAMoogLadder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the Moog Ladder lowpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, sig: SIMD[DType.float64, num_chans], freq: SIMD[DType.float64, num_chans] = 100, q: SIMD[DType.float64, num_chans] = 0.5) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sig** | `SIMD` | — | The input signal to process. |
| **freq** | `SIMD` | `100` | The cutoff frequency of the lowpass filter. |
| **q** | `SIMD` | `0.5` | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span>
**Resonant filter with lowpass, highpass, and bandpass modes.**

<!-- DESCRIPTION -->
A translation of Julius Smith's Faust implementation of [tf2s (virtual analog) resonant filters](https://github.com/grame-cncm/faustlibraries/blob/6061da8bf2279ae4281333861a3dc6254e9076f9/filters.lib#L2054).
Copyright (C) 2003-2019 by Julius O. Smith III



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of SIMD channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Reson filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a resonant lowpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Signature**  

```mojo
lpf(mut self, input: SIMD[DType.float64, num_chans], freq: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **freq** | `SIMD` | — | The cutoff frequency of the lowpass filter. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain** | `SIMD` | — | The output gain (clipped to 0.0-1.0 range). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a resonant highpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Signature**  

```mojo
hpf(mut self, input: SIMD[DType.float64, num_chans], freq: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **freq** | `SIMD` | — | The cutoff frequency of the highpass filter. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain** | `SIMD` | — | The output gain (clipped to 0.0-1.0 range). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Reson</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a resonant bandpass filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Signature**  

```mojo
bpf(mut self, input: SIMD[DType.float64, num_chans], freq: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **freq** | `SIMD` | — | The center frequency of the bandpass filter. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain** | `SIMD` | — | The output gain (clipped to 0.0-1.0 range). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span>
**A Biquad filter struct.**

<!-- DESCRIPTION -->
To use the different modes, see the mode-specific methods.

Based on [Robert Bristow-Johnson's Audio EQ Cookbook](https://webaudio.github.io/Audio-EQ-Cookbook/audio-eq-cookbook.html). 



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of SIMD channels to process in parallel. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Biquad.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">reset</span>

<div style="margin-left:3em;" markdown="1">

Clears any leftover internal state so the filter starts clean after interruptions or discontinuities in the audio stream.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">reset</span> **Signature**  

```mojo
reset(mut self)
```







<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad lowpass filter. Passes frequencies below the cutoff while attenuating frequencies above it.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Signature**  

```mojo
lpf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad highpass filter. Passes frequencies above the cutoff while attenuating frequencies below it.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Signature**  

```mojo
hpf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad bandpass filter. Passes a band of frequencies centered at the cutoff while attenuating frequencies above and below.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Signature**  

```mojo
bpf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The bandwidth of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bpf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad notch (band stop) filter. Attenuates a narrow band of frequencies centered at the cutoff while passing all others.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span> **Signature**  

```mojo
notch(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notch</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad allpass filter. Passes all frequencies at equal amplitude while shifting their phase relationship around the cutoff frequency.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span> **Signature**  

```mojo
allpass(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">allpass</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad bell (peaking EQ) filter. Boosts or cuts a band of frequencies centered at the cutoff by a specified gain amount, leaving frequencies outside the band unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span> **Signature**  

```mojo
bell(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain_db: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain_db** | `SIMD` | — | The amount to boost/cut around the cutoff. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bell</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad lowshelf filter. Boosts or cuts all frequencies below the cutoff by a specified gain amount, leaving frequencies above unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span> **Signature**  

```mojo
lowshelf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain_db: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain_db** | `SIMD` | — | The amount to boost/cut around the cutoff. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lowshelf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Biquad</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span>

<div style="margin-left:3em;" markdown="1">

Process input through a biquad highshelf filter. Boosts or cuts all frequencies above the cutoff by a specified gain amount, leaving frequencies below unaffected.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span> **Signature**  

```mojo
highshelf(mut self, input: SIMD[DType.float64, num_chans], frequency: SIMD[DType.float64, num_chans], q: SIMD[DType.float64, num_chans], gain_db: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input signal to process. |
| **frequency** | `SIMD` | — | The cutoff frequency in Hz. |
| **q** | `SIMD` | — | The resonance of the filter. |
| **gain_db** | `SIMD` | — | The amount to boost/cut around the cutoff. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">highshelf</span> **Returns**
: `SIMD`
The next sample of the filtered output.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
