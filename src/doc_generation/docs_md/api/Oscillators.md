

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span>
**Phasor Oscillator.**

<!-- DESCRIPTION -->
An oscillator that generates a ramp waveform from 0.0 to 1.0. The phasor is the root of all oscillators in MMMAudio.

The Phasor can act as a simple phasor with the .next() function. 

However, it can also be an impulse with next_impulse() and a boolean impulse with next_bool().



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels. |
| **os_index** | `Int` | `0` | Oversampling index (0 = no oversampling, 1 = 2x, up to 4 = 16x). Phasor does not downsample its output, so oversampling is only useful when used as part of other oversampled oscillators. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Creates the next sample of the phasor output based on the inputs.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: Phasor[num_chans, os_index], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](True)) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the phasor in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator. |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](True)` | Trigger signal to reset the phase when switching from False to True. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample of the phasor output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span>

<div style="margin-left:3em;" markdown="1">

Increments the phasor and returns a boolean impulse when the phase wraps around from 1.0 to 0.0. This only works with possive frequencies and phase offsets between 0.0 and 1.0.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Signature**  

```mojo
next_bool(mut self, freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](True)) -> SIMD[DType.bool, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the phasor in Hz (default is 100.0). |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](True)` | Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Returns**
: `SIMD`
A boolean SIMD indicating True when the impulse occurs.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Phasor</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_impulse</span>

<div style="margin-left:3em;" markdown="1">

Generates an impulse waveform where the output is 1.0 for one sample when the phase wraps around from 1.0 to 0.0, and 0.0 otherwise. This only works with possive frequencies and phase offsets between 0.0 and 1.0.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_impulse</span> **Signature**  

```mojo
next_impulse(mut self, freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](True)) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_impulse</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the phasor in Hz (default is 100.0). |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](True)` | Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_impulse</span> **Returns**
: `SIMD`
The next impulse sample as a Float64. 1.0 when the impulse occurs, 0.0 otherwise.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Impulse</span>
**Impulse Oscillator.**

<!-- DESCRIPTION -->
An oscillator that outputs a 1.0 or True for one sample when the phase wraps around from 1.0 to 0.0.

Impulse is essentially a wrapper around the Phasor oscillator that provides impulse-specific methods.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Impulse</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels (default is 1). |
| **os_index** | `Int` | `0` | Oversampling index (0 = no oversampling, 1 = 2x, etc.; default is 0). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Impulse</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Impulse</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Impulse</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span>

<div style="margin-left:3em;" markdown="1">

Increments the phasor and returns a boolean impulse when the phase wraps around from 1.0 to 0.0.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Signature**  

```mojo
next_bool(mut self, freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](True)) -> SIMD[DType.bool, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the phasor in Hz (default is 100.0). |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](True)` | Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Returns**
: `SIMD`
A boolean SIMD indicating True when the impulse occurs.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Impulse</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generates an impulse waveform where the output is 1.0 for one sample when the phase wraps around from 1.0 to 0.0, and 0.0 otherwise.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](True)) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the phasor in Hz (default is 100.0). |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](True)` | Trigger signal to reset the phase when switching from False to True (default is all True, which resets the phasor on the first sample). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next impulse sample as a Float64. 1.0 when the impulse occurs, 0.0 otherwise.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span>
**Wavetable Oscillator Core.**

<!-- DESCRIPTION -->
A wavetable oscillator capable of all standard waveforms and also able to load custom wavetables. Capable of linear, cubic, quadratic, lagrange, or sinc interpolation. Also capable of [Oversampling](Oversampling.md).

- Pure tones can be generated without oversampling or sinc interpolation.
- When doing extreme modulation, best practice is to use sinc interpolation and an oversampling index of 1 (2x).
- Try all the combinations of interpolation and oversampling to find the best tradeoff between quality and CPU usage for your application.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels (default is 1). |
| **interp** | `Int` | `Interp.linear` | Interpolation method. See [Interp](MMMWorld.md/#struct-interp) struct for options (default is Interp.linear). |
| **os_index** | `Int` | `0` | [Oversampling](Oversampling.md) index (0 = no oversampling, 1 = 2x, 2 = 4x, etc.; default is 0). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next oscillator sample on a single waveform type. All inputs are SIMD types except trig, which is a scalar. This means that an oscillator can have num_chans different instances, each with its own frequency, phase offset, and waveform type, but they will all share the same trigger signal.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: Osc[num_chans, interp, os_index], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False, osc_type: SIMD[DType.index, num_chans] = OscType.sine) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the oscillator in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True (default is 0.0). |
| **osc_type** | `SIMD` | `OscType.sine` | Type of waveform. See the OscType struct for options (default is OscType.sine). Best if provided as OscType.sine, OscType.triangle, etc. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample of the oscillator output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_all_basic_waveforms</span>

<div style="margin-left:3em;" markdown="1">

Returns the next sample of all basic waveforms (sine, triangle, saw, square) in a SIMD vector, where each waveform is in a different lane.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_all_basic_waveforms</span> **Signature**  

```mojo
next_all_basic_waveforms(mut self, freq: Float64 = 100, phase: Float64 = 0, last_phase: Float64 = 0, trig: Bool = False) -> SIMD[DType.float64, 4]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_all_basic_waveforms</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `Float64` | `100` | — |
| **phase** | `Float64` | `0` | — |
| **last_phase** | `Float64` | `0` | — |
| **trig** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_all_basic_waveforms</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_basic_waveforms</span>

<div style="margin-left:3em;" markdown="1">

Variable Wavetable Oscillator using built-in waveforms. Generates the next oscillator sample on a variable  waveform where the output is interpolated between  different waveform types. All inputs are SIMD types except trig and osc_types, which are scalar. This  means that an oscillator can have num_chans different instances, each with its own frequency, phase offset,  and waveform type, but they will all share the same trigger signal and the same list of waveform types  to interpolate between.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_basic_waveforms</span> **Signature**  

```mojo
next_basic_waveforms(mut self, freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False, osc_types: List[Int] = List[Int](OscType.sine, OscType.triangle, OscType.saw, OscType.square, Tuple[]()), osc_frac: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_basic_waveforms</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the oscillator in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True (default is 0.0). |
| **osc_types** | `List` | `List[Int](OscType.sine, OscType.triangle, OscType.saw, OscType.square, Tuple[]())` | List of waveform types ([OscType](MMMWorld.md/#struct-osctype)) to interpolate between (default is [OscType.sine,OscType.triangle,OscType.saw,OscType.square]. |
| **osc_frac** | `SIMD` | `0` | Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first waveform in the osc_types list, 1.0 corresponds to the last waveform in the osc_types list, and values in between interpolate linearly between all waveforms in the list. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_basic_waveforms</span> **Returns**
: `SIMD`
The next sample of the oscillator output.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span>

<div style="margin-left:3em;" markdown="1">

Variable Wavetable Oscillator that interpolates over a loaded Buffer. Generates the next oscillator sample on a variable waveform where the output is interpolated between  different different channels of a provided Buffer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Signature**  

```mojo
next_vwt(mut self: Osc[num_chans, interp, os_index], ref buffer: Buffer, freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False, osc_frac: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `Buffer` | — | Reference to a Buffer containing the waveforms to interpolate between. |
| **freq** | `SIMD` | `100` | Frequency of the oscillator in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True (default is 0.0). All waveforms will reset together. |
| **osc_frac** | `SIMD` | `0` | Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first channel in the input buffer, 1.0 corresponds to the last channel in the input buffer, and values in between interpolate linearly between all channels in the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Osc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span>

<div style="margin-left:3em;" markdown="1">

Variable Wavetable Oscillator that interpolates over a loaded SIMDBuffer. Generates the next oscillator sample on a variable waveform where the output is interpolated between  different different channels of a provided Buffer. This should only be used with low channel counts (maybe up to 4 or 8 channels depending on the CPU).

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Signature**  

```mojo
next_vwt[simd_chans: Int](mut self: Osc[num_chans, interp, os_index], ref buffer: SIMDBuffer[simd_chans], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False, osc_frac: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **simd_chans** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `SIMDBuffer` | — | Reference to a Buffer containing the waveforms to interpolate between. |
| **freq** | `SIMD` | `100` | Frequency of the oscillator in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True (default is 0.0). All waveforms will reset together. |
| **osc_frac** | `SIMD` | `0` | Fractional index for wavetable interpolation. Values are between 0.0 and 1.0. 0.0 corresponds to the first channel in the input buffer, 1.0 corresponds to the last channel in the input buffer, and values in between interpolate linearly between all channels in the buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_vwt</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SinOsc</span>
**A sine wave oscillator.**

<!-- DESCRIPTION -->
This is a convenience struct as internally it uses [Osc](Oscillators.md/#struct-osc) and indicates `osc_type = OscType.sine`.

Args:
    world: Pointer to the MMMWorld instance.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SinOsc</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels (default is 1). |
| **os_index** | `Int` | `0` | Oversampling index (0 = no oversampling, 1 = 2x, etc.; default is 0). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SinOsc</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SinOsc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SinOsc</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: SinOsc[num_chans, os_index], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False, interp: Int = 0) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | — |
| **phase_offset** | `SIMD` | `0` | — |
| **trig** | `Bool` | `False` | — |
| **interp** | `Int` | `0` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSaw</span>
**A low-frequency sawtooth oscillator.**

<!-- DESCRIPTION -->
This oscillator generates a non-bandlimited sawtooth waveform. It is useful for modulation, but should be avoided for audio-rate synthesis due to comptimeing.

Outputs values between 0.0 and 1.0.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSaw</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels (default is 1). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSaw</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSaw</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSaw</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next sawtooth wave sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: LFSaw[num_chans], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the sawtooth wave in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True (default is 0.0). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSquare</span>
**A low-frequency square wave oscillator.**

<!-- DESCRIPTION -->
Creates a non-band-limited square wave. Outputs values of -1.0 or 1.0. Useful for modulation, but should be avoided for audio-rate synthesis due to comptimeing.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSquare</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels (default is 1). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSquare</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSquare</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFSquare</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next square wave sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: LFSquare[num_chans], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the square wave in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator (default is 0.0). |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True (default is 0.0). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFTri</span>
**A low-frequency triangle wave oscillator.**

<!-- DESCRIPTION -->
This oscillator generates a triangle wave at audio rate. It is useful for 
modulation, but should be avoided for audio-rate synthesis due to comptimeing.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFTri</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels (default is 1). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFTri</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFTri</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFTri</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next triangle wave sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: LFTri[num_chans], freq: SIMD[DType.float64, num_chans] = 100, phase_offset: SIMD[DType.float64, num_chans] = 0, trig: Bool = False) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the triangle wave in Hz. |
| **phase_offset** | `SIMD` | `0` | Offsets the phase of the oscillator. |
| **trig** | `Bool` | `False` | Trigger signal to reset the phase when switching from False to True. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span>
**A dust noise oscillator that generates random impulses at random intervals.**

<!-- DESCRIPTION -->
Dust has a Phasor as its core, and the frequency of the Phasor is randomly changed each time an impulse is generated. This allows the Dust to be used in multiple ways. It can be used as a simple random impulse generator, or the user can use the get_phase() method to get the current phase of the internal Phasor and use that phase to drive other oscillators or processes. The user can also set the phase of the internal Phasor using the set_phase() method, allowing for more complex interactions.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next dust noise sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: Dust[num_chans], low: SIMD[DType.float64, num_chans] = 100, high: SIMD[DType.float64, num_chans] = 2000, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](False)) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **low** | `SIMD` | `100` | Lower bound for the random frequency range. |
| **high** | `SIMD` | `2000` | Upper bound for the random frequency range. |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](False)` | Trigger signal to reset the phase when switching from False to True. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next dust noise sample as a Float64. Will be 1.0 when an impulse occurs, 0.0 otherwise.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span>

<div style="margin-left:3em;" markdown="1">

Generate the next dust noise sample as a boolean impulse.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Signature**  

```mojo
next_bool(mut self: Dust[num_chans], low: SIMD[DType.float64, num_chans] = 100, high: SIMD[DType.float64, num_chans] = 2000, trig: SIMD[DType.bool, num_chans] = SIMD[DType.bool, num_chans](False)) -> SIMD[DType.bool, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **low** | `SIMD` | `100` | Lower bound for the random frequency range. |
| **high** | `SIMD` | `2000` | Upper bound for the random frequency range. |
| **trig** | `SIMD` | `SIMD[DType.bool, num_chans](False)` | Trigger signal to reset the phase when switching from False to True. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_bool</span> **Returns**
: `SIMD`
The next dust noise sample as a boolean SIMD. Will be True when an impulse occurs, False otherwise.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_phase</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_phase</span> **Signature**  

```mojo
get_phase(self) -> SIMD[DType.float64, num_chans]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_phase</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Dust</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_phase</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_phase</span> **Signature**  

```mojo
set_phase(mut self, phase: SIMD[DType.float64, num_chans])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_phase</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **phase** | `SIMD` | — | — |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFNoise</span>
**Low-frequency interpolating noise generator generating numbers between -1.0 and 1.0. With stepped (none), linear, or cubic interpolation.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFNoise</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels. |
| **interp** | `Int` | `Interp.cubic` | Interpolation method. Options are Interp.none (stepped), Interp.linear, Interp.cubic. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFNoise</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFNoise</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">LFNoise</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next low-frequency noise sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self: LFNoise[num_chans, interp], freq: SIMD[DType.float64, num_chans] = 100) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the noise in Hz. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample as a Float64.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Sweep</span>
**A phase accumulator.**

<!-- DESCRIPTION -->
Phase accumulator that sweeps from 0 up to inf at a given frequency, resetting on trigger.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Sweep</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of channels. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Sweep</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Sweep</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: Pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Sweep</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next sweep sample.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, freq: SIMD[DType.float64, num_chans] = 100, trig: SIMD[DType.bool, num_chans] = False) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | `100` | Frequency of the sweep in Hz. |
| **trig** | `SIMD` | `False` | Trigger signal to reset the phase when switching from False to True (default is all False). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample as a Float64.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
