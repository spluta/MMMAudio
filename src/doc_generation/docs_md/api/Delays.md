

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span>
**A variable delay line with interpolation.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Size of the SIMD vector - defaults to 1. |
| **interp** | `Int` | `Interp.linear` | The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Delay line.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], max_delay_time: Float64 = 1)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **max_delay_time** | `Float64` | `1` | The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Delay line.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], max_delay_samples: Int = 1024)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **max_delay_samples** | `Int` | `1024` | The maximum delay time in samples. The internal buffer will be allocated to accommodate this delay. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span>

<div style="margin-left:3em;" markdown="1">

Reads into the delay line at an exact sample delay and no interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Signature**  

```mojo
read[N: Int](mut self, var delay_samps: SIMD[DType.index, N]) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **N** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **delay_samps** | `SIMD` | — | The amount of delay to apply (in samples). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Returns**
: `SIMD`
A single sample read from the delay buffer with no interpolation. Use a float lookup for fractional delay with interpolation.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span>

<div style="margin-left:3em;" markdown="1">

Reads into the delay line.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Signature**  

```mojo
read[N: Int](mut self, var delay_time: SIMD[DType.float64, N]) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **N** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **delay_time** | `SIMD` | — | The amount of delay to apply (in seconds). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read</span> **Returns**
: `SIMD`
A single sample read from the delay buffer.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write</span>

<div style="margin-left:3em;" markdown="1">

Writes a single sampleinto the delay line.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write</span> **Signature**  

```mojo
write(mut self, input: SIMD[DType.float64, num_chans])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the delay line, first reading from the delay then writing into it. This version uses an integer lookup into the delay line and no interpolation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[N: Int](mut self, input: SIMD[DType.float64, num_chans], delay_samps: SIMD[DType.index, N]) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **N** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_samps** | `SIMD` | — | The amount of delay to apply (in samples). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The processed output sample.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the delay line, first reading from the delay then writing into it.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[N: Int](mut self, input: SIMD[DType.float64, num_chans], var delay_time: SIMD[DType.float64, N]) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **N** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | — | The amount of delay to apply (in seconds). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The processed output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_f_idx</span>

<div style="margin-left:3em;" markdown="1">

Calculate the fractional index in the delay buffer for the given delay time.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_f_idx</span> **Signature**  

```mojo
get_f_idx(self, delay_time: Float64) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_f_idx</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **delay_time** | `Float64` | — | The delay time in seconds. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_f_idx</span> **Returns**
: `Float64`
The fractional index in the delay buffer.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Comb</span>
**A simple comb filter using a delay line with feedback.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Comb</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Size of the SIMD vector. |
| **interp** | `Int` | `2` | The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Comb</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Comb filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], max_delay: Float64 = 1)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **max_delay** | `Float64` | `1` | The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the comb filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: SIMD[DType.float64, num_chans], delay_time: SIMD[DType.float64, num_chans] = 0, feedback: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | `0` | The amount of delay to apply (in seconds). |
| **feedback** | `SIMD` | `0` | The amount of feedback to apply (-1.0 to 1.0). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The delayed output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the comb filter with decay time calculation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span> **Signature**  

```mojo
next_decaytime(mut self, input: SIMD[DType.float64, num_chans], delay_time: SIMD[DType.float64, num_chans], decay_time: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | — | The amount of delay to apply (in seconds). |
| **decay_time** | `SIMD` | — | The desired decay time (time to -60dB). Feedback is calculated internally. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span> **Returns**
: `SIMD`
The delayed output sample.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LP_Comb</span>
**A simple comb filter with an integrated one-pole low-pass filter.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LP_Comb</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Size of the SIMD vector - defaults to 1. |
| **interp** | `Int` | `Interp.linear` | The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LP_Comb</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LP_Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the LP_Comb filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], max_delay: Float64 = 1)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **max_delay** | `Float64` | `1` | The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LP_Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the comb filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: SIMD[DType.float64, num_chans], delay_time: SIMD[DType.float64, num_chans] = 0, feedback: SIMD[DType.float64, num_chans] = 0, lp_freq: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | `0` | The amount of delay to apply (in seconds). |
| **feedback** | `SIMD` | `0` | The amount of feedback to apply (-1.0 to 1.0). |
| **lp_freq** | `SIMD` | `0` | The cutoff frequency of the OnePole filter in the feedback loop. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The processed output sample.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Allpass_Comb</span>
**A simple allpass comb filter using a delay line with feedback.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Allpass_Comb</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Size of the SIMD vector. |
| **interp** | `Int` | `Interp.linear` | The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Allpass_Comb</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Allpass_Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Allpass Comb filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], max_delay: Float64 = 1)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **max_delay** | `Float64` | `1` | The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Allpass_Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the allpass comb filter.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: SIMD[DType.float64, num_chans], delay_time: SIMD[DType.float64, num_chans] = 0, feedback_coef: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | `0` | The amount of delay to apply (in seconds). |
| **feedback_coef** | `SIMD` | `0` | The feedback coefficient (-1.0 to 1.0). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The delayed/filtered output sample.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Allpass_Comb</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span>

<div style="margin-left:3em;" markdown="1">

Process one sample through the allpass comb filter with decay time calculation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span> **Signature**  

```mojo
next_decaytime(mut self, input: SIMD[DType.float64, num_chans], delay_time: SIMD[DType.float64, num_chans], decay_time: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | — | The amount of delay to apply (in seconds). |
| **decay_time** | `SIMD` | — | The desired decay time (time to -60dB). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_decaytime</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FB_Delay</span>
**A feedback delay structured like a Comb filter, but with possible feedback coefficient above 1 due to an integrated tanh function.**

<!-- DESCRIPTION -->
By default, Anti-comptimeing is disabled and no [oversampling](Oversampling.md) is applied, but this can be changed by setting the ADAA_dist and os_index template parameters.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FB_Delay</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Size of the SIMD vector. |
| **interp** | `Int` | `Interp.lagrange4` | The interpolation method to use. See the struct [Interp](MMMWorld.md#struct-interp) for interpolation options. |
| **ADAA_dist** | `Bool` | `False` | Whether to apply ADAA distortion to the feedback signal instead of standard tanh. |
| **os_index** | `Int` | `0` | The [oversampling](Oversampling.md) index for ADAA distortion. 0 = no oversampling, 1 = 2x, 2 = 4x, 3 = 8x, 4 = 16x. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FB_Delay</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FB_Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the FB_Delay.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], max_delay: Float64 = 1)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld. |
| **max_delay** | `Float64` | `1` | The maximum delay time in seconds. The internal buffer will be allocated to accommodate this delay. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">FB_Delay</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Process one sample or SIMD vector through the feedback delay.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: SIMD[DType.float64, num_chans], delay_time: SIMD[DType.float64, num_chans], feedback: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The input sample to process. |
| **delay_time** | `SIMD` | — | The amount of delay to apply (in seconds). |
| **feedback** | `SIMD` | — | The amount of feedback to apply (0.0 to 1.0). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The processed output sample or SIMD vector.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">calc_feedback</span>

<div style="margin-left:3em;" markdown="1">

Calculate the feedback coefficient for a Comb filter or Allpass line based on desired delay time and decay time.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
calc_feedback[num_chans: Int = 1](delaytime: SIMD[DType.float64, num_chans], decaytime: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector - defaults to 1. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **delaytime** | `SIMD` | — | The delay time in seconds. |
| **decaytime** | `SIMD` | — | The decay time in seconds (time to -60dB). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
