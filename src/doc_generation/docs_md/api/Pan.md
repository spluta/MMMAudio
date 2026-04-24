

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SplayN</span>
**SplayN - Splays multiple input channels into N output channels. Different from `splay` which only outputs stereo, SplayN can output to any number of channels.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SplayN</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_channels** | `Int` | `2` | Number of output channels to splay to. |
| **pan_points** | `Int` | `128` | Number of discrete pan points to use for panning calculations. Default is 128. |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SplayN</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SplayN</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the SplayN instance.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | Pointer to the MMMWorld instance. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SplayN</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Evenly distributes multiple input channels to num_channels of output channels.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[num_simd: Int](mut self, input: List[SIMD[DType.float64, num_simd]]) -> SIMD[DType.float64, num_channels]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_simd** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `List` | — | List of input samples from multiple channels. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
MFloat[self.num_channels]: The panned output sample for each output channel.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">pan2</span>

<div style="margin-left:3em;" markdown="1">

Simple constant power panning function.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
pan2(samples: Float64, pan: Float64) -> SIMD[DType.float64, 2]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **samples** | `Float64` | — | Float64 - Mono input sample. |
| **pan** | `Float64` | — | Float64 - Pan value from -1.0 (left) to 1.0 (right). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Stereo output as MFloat[2].
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">pan_stereo</span>

<div style="margin-left:3em;" markdown="1">

Simple constant power panning function for stereo samples.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
pan_stereo(samples: SIMD[DType.float64, 2], pan: Float64) -> SIMD[DType.float64, 2]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **samples** | `SIMD` | — | MFloat[2] - Stereo input sample. |
| **pan** | `Float64` | — | Float64 - Pan value from -1.0 (left) to 1.0 (right). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Stereo output as MFloat[2].
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">splay</span>

<div style="margin-left:3em;" markdown="1">

Splay multiple input channels into stereo output.
 <!-- endif overload.summary -->

There are multiple versions of splay to handle different input types. It can take a list of SIMD vectors or a single 1 or many channel SIMD vector. In the case of a list of SIMD vectors, each channel within the vector is treated separately and panned individually.

 <!-- end if overload.description -->

**Signature**

```mojo
splay[num_simd: Int](input: List[SIMD[DType.float64, num_simd]], world: UnsafePointer[MMMWorld, MutExternalOrigin]) -> SIMD[DType.float64, 2]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_simd** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `List` | — | List of input samples from multiple channels. |
| **world** | `UnsafePointer` | — | Pointer to MMMWorld containing the pan_window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Stereo output as MFloat[2].
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>

<div style="border-top: 2px solid #247fffff; margin: 20px 0;"></div>


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">splay</span>

<div style="margin-left:3em;" markdown="1">

Splay multiple input channels into stereo output.
 <!-- endif overload.summary -->

There are multiple versions of splay to handle different input types. It can take a list of SIMD vectors or a single 1 or many channel SIMD vector. In the case of a list of SIMD vectors, each channel within the vector is treated separately and panned individually.

 <!-- end if overload.description -->

**Signature**

```mojo
splay[num_input_channels: Int](input: SIMD[DType.float64, num_input_channels], world: UnsafePointer[MMMWorld, MutExternalOrigin]) -> SIMD[DType.float64, 2]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_input_channels** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | List of input samples from multiple channels. List of Float64 or List of SIMD vectors. |
| **world** | `UnsafePointer` | — | Pointer to MMMWorld containing the pan_window. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Stereo output as MFloat[2].
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">pan_az</span>

<div style="margin-left:3em;" markdown="1">

Pan a mono sample to N speakers arranged in a circle around the listener using azimuth panning.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
pan_az[simd_out_size: Int = 2](sample: Float64, pan: Float64, num_speakers: Int, width: Float64 = 2, orientation: Float64 = 0.5) -> SIMD[DType.float64, simd_out_size]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **simd_out_size** | `Int` | Number of output channels (speakers). Must be a power of two that is at least as large as num_speakers. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sample** | `Float64` | — | Mono input sample. |
| **pan** | `Float64` | — | Pan position from 0.0 to 1.0. |
| **num_speakers** | `Int` | — | Number of speakers to pan to. |
| **width** | `Float64` | `2` | Width of the speaker array (default is 2.0). |
| **orientation** | `Float64` | `0.5` | Orientation offset of the speaker array (default is 0.5). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
MFloat[simd_out_size]: The panned output sample for each speaker.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
