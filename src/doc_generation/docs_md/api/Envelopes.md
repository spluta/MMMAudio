Envelope generator module.

This module provides an envelope generator class that can create complex envelopes with multiple segments, curves, and looping capabilities.

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">EnvParams</span>
**Parameters for the Env class.**

<!-- DESCRIPTION -->
This struct holds the parameters for the envelope generator. It
is not required to use the `Env` struct, but it might be convenient.


Elements:

values: List of envelope values at each breakpoint.  
times: List of durations (in seconds) for each segment between adjacent breakpoints. This List should be one element shorter than the `values` List.  
curves: List of curve shapes for each segment. Positive values for convex "exponential" curves, negative for concave "logarithmic" curves. (if the output of the envelope is negative, the curve will be inverted).  
loop: Bool to indicate if the envelope should loop.  
time_warp: Time warp factor to speed up or slow down the envelope. Default is 1.0 meaning no warp. A value of 2.0 will make the envelop take twice as long to complete. A value of 0.5 will make the envelope take half as long to complete.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">EnvParams</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">EnvParams</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize EnvParams.
For information on the arguments, see the documentation of the `Env::next()` method that takes each parameter individually.
`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, values: List[Float64] = List[Float64](0, 1, 0, Tuple[]()), times: List[Float64] = List[Float64](1, 1, Tuple[]()), curves: List[Float64] = List[Float64](1, Tuple[]()), loop: Bool = False, time_warp: Float64 = 1)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **values** | `List` | `List[Float64](0, 1, 0, Tuple[]())` | — |
| **times** | `List` | `List[Float64](1, 1, Tuple[]())` | — |
| **curves** | `List` | `List[Float64](1, Tuple[]())` | — |
| **loop** | `Bool` | `False` | — |
| **time_warp** | `Float64` | `1` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Env</span>
**Envelope generator with an arbitrary number of segments.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Env</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Env</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Env2 struct - with internal params.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Env</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next envelope value. Uses the internal `params` struct for envelope parameters. See `EnvParams` for more details on the parameters.          Args:         trig: Trigger to start the envelope.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, trig: Bool = True) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **trig** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ASREnv</span>
**Simple ASR envelope generator.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ASREnv</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ASREnv</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the ASREnv struct.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ASREnv</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Simple ASR envelope generator.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, attack: Float64, sustain: Float64, release: Float64, gate: Bool, curve: SIMD[DType.float64, 2] = 1) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **attack** | `Float64` | — | (Float64): Attack time in seconds. |
| **sustain** | `Float64` | — | (Float64): Sustain level (0 to 1). |
| **release** | `Float64` | — | (Float64): Release time in seconds. |
| **gate** | `Bool` | — | (Bool): Gate signal (True or False). |
| **curve** | `SIMD` | `1` | (MFloat[2]): Can pass a Float64 for equivalent curve on rise and fall or MFloat[2] for different rise and fall curve. Positive values for convex "exponential" curves, negative for concave "logarithmic" curves. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">min_env</span>

<div style="margin-left:3em;" markdown="1">

Simple envelope.
 <!-- endif overload.summary -->

Envelope that rises linearly from 0 to 1 over `rampdur` seconds, stays at 1 until `totaldur - rampdur`, 
then falls linearly back to 0 over the final `rampdur` seconds. This envelope isn't "triggered," instead
the user provides the current phase between 0 (beginning) and 1 (end) of the envelope.

 <!-- end if overload.description -->

**Signature**

```mojo
min_env[N: Int = 1](phase: SIMD[DType.float64, N] = 0.01, totaldur: SIMD[DType.float64, N] = 0.10000000000000001, rampdur: SIMD[DType.float64, N] = 0.001) -> SIMD[DType.float64, N]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **N** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **phase** | `SIMD` | `0.01` | Current env position between 0 (beginning) and 1 (end). |
| **totaldur** | `SIMD` | `0.10000000000000001` | Total duration of the envelope. |
| **rampdur** | `SIMD` | `0.001` | Duration of the rise and fall segments that occur at the beginning and end of the envelope. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Envelope value at the current ramp position.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
