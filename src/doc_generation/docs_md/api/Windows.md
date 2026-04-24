

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Windows</span>
**Stores various window functions used in audio processing. This struct precomputes several common window types.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Windows</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Windows</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self)
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Windows</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">at_phase</span>

<div style="margin-left:3em;" markdown="1">

Get window value at given phase (0.0 to 1.0) for specified window type.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">at_phase</span> **Signature**  

```mojo
at_phase[window_type: Int, interp: Int = Interp.none](self, world: UnsafePointer[MMMWorld, MutExternalOrigin], phase: Float64, prev_phase: Float64 = 0) -> Float64
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">at_phase</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **window_type** | `Int` | — | — |
| **interp** | `Int` | `Interp.none` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">at_phase</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | — |
| **phase** | `Float64` | — | — |
| **prev_phase** | `Float64` | `0` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">at_phase</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Windows</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">make_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a window of specified type and size.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">make_window</span> **Signature**  

```mojo
make_window[window_type: Int](size: Int, beta: Float64 = 5) -> List[Float64]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">make_window</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **window_type** | `Int` | — | Type of window to generate. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">make_window</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
| **beta** | `Float64` | `5` | Shape parameter only used for Kaiser window. See kaiser_window() for details. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">make_window</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">rect_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a rectangular window of length size.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
rect_window(size: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List containing the rectangular window values (all ones).
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">tri_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a triangular window of length size. Args:     size: Length of the window. Returns:     List containing the triangular window values.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
tri_window(size: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">bessel_i0</span>

<div style="margin-left:3em;" markdown="1">

Calculate the modified Bessel function of the first kind, order 0 (I₀). Uses polynomial approximation for accurate results.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
bessel_i0(x: Float64) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **x** | `Float64` | — | Input value. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64`
I₀(x).
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">kaiser_window</span>

<div style="margin-left:3em;" markdown="1">

Create a Kaiser window of length n with shape parameter beta.
 <!-- endif overload.summary -->

- beta = 0: rectangular window.
- beta = 5: similar to Hamming window.
- beta = 6: similar to Hanning window.
- beta = 8.6: similar to Blackman window.

 <!-- end if overload.description -->

**Signature**

```mojo
kaiser_window(size: Int, beta: Float64) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
| **beta** | `Float64` | — | Shape parameter that controls the trade-off between main lobe width and side lobe level. See description for details. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List[Float64] containing the Kaiser window coefficients.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hann_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a Hann window of length size.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
hann_window(size: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List containing the Hann window values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hamming_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a Hamming window of length size.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
hamming_window(size: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List containing the Hamming window values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">blackman_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a Blackman window of length size.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
blackman_window(size: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List containing the Blackman window values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sine_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a Sine window of length size.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
sine_window(size: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List containing the Sine window values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">pan2_window</span>

<div style="margin-left:3em;" markdown="1">

Generate a MFloat[2] quarter cosine window for panning. The first element of the SIMD vector is the multiplier for the left channel, and the second element is for the right channel. This allows any sample to be panned at one of `size` positions between left and right channels smoothly.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
pan2_window(size: Int) -> List[SIMD[DType.float64, 2]]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **size** | `Int` | — | Length of the window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
List containing the quarter cosine window values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
