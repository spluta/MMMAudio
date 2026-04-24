

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span>
**A struct for storing a buffer and recording audio into it.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | The number of channels in the buffer. Default is 1 (mono). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Recorder struct.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], num_frames: Int, sample_rate: Float64)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | A pointer to the MMMWorld instance. |
| **num_frames** | `Int` | — | The number of frames in the empty buffer to be recorded to. |
| **sample_rate** | `Float64` | — | The sample rate of the empty buffer. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">replace_buffer</span>

<div style="margin-left:3em;" markdown="1">

Replace the internal buffer with a new buffer. The new buffer must have the same number of channels as the existing buffer. Write head is reset to 0.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">replace_buffer</span> **Signature**  

```mojo
replace_buffer(mut self, new_buf: SIMDBuffer[num_chans])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">replace_buffer</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **new_buf** | `SIMDBuffer` | — | The new buffer to replace the existing buffer with. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write</span>

<div style="margin-left:3em;" markdown="1">

Write SIMD input to buffer at specified index. Used internally by write_next and write_previous, which will be more appropriate for most use cases.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write</span> **Signature**  

```mojo
write(mut self, input: SIMD[DType.float64, num_chans], index: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The SIMD input to write to the buffer. |
| **index** | `Int` | — | The index in the buffer to write the input to. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_next</span>

<div style="margin-left:3em;" markdown="1">

Write SIMD input to buffer at current write head and advance write head forward. This is the correct option in most use cases.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_next</span> **Signature**  

```mojo
write_next(mut self, value: SIMD[DType.float64, num_chans])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **value** | `SIMD` | — | The SIMD input to write to the buffer. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Recorder</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_previous</span>

<div style="margin-left:3em;" markdown="1">

Write SIMD input to buffer at current write head and move write head backward. This is useful for things like delay lines, which write backwards through a buffer so they can interpolate forwards.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_previous</span> **Signature**  

```mojo
write_previous(mut self, value: SIMD[DType.float64, num_chans])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_previous</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **value** | `SIMD` | — | The SIMD input to write to the buffer. |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
