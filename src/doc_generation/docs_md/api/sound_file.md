

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">WavHeader</span>
**Struct containing WAV file header information.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">WavHeader</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">WavHeader</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

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



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_8bit_sample</span>

<div style="margin-left:3em;" markdown="1">

Read 8-bit unsigned PCM sample and normalize to [-1.0, 1.0].
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_8bit_sample(data: List[UInt8], offset: Int) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **offset** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_16bit_sample</span>

<div style="margin-left:3em;" markdown="1">

Read 16-bit signed PCM sample and normalize to [-1.0, 1.0].
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_16bit_sample(data: List[UInt8], offset: Int) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **offset** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_24bit_sample</span>

<div style="margin-left:3em;" markdown="1">

Read 24-bit signed PCM sample and normalize to [-1.0, 1.0].
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_24bit_sample(data: List[UInt8], offset: Int) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **offset** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_32bit_sample</span>

<div style="margin-left:3em;" markdown="1">

Read 32-bit signed PCM sample and normalize to [-1.0, 1.0].
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_32bit_sample(data: List[UInt8], offset: Int) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **offset** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_float32_sample</span>

<div style="margin-left:3em;" markdown="1">

Read 32-bit float sample (already normalized).
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_float32_sample(data: List[UInt8], offset: Int) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **offset** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_float64_sample</span>

<div style="margin-left:3em;" markdown="1">

Read 64-bit float sample (already normalized).
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_float64_sample(data: List[UInt8], offset: Int) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **offset** | `Int` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_wav_header</span>

<div style="margin-left:3em;" markdown="1">

Parse WAV header from file data.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_wav_header(file_name: String) -> WavHeader
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | Path to the WAV file. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `WavHeader` <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_wav_samples</span>

<div style="margin-left:3em;" markdown="1">

Read all audio samples from WAV file data.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_wav_samples(file_name: String, header: WavHeader, num_wavetables: Int = 1) -> List[List[Float64]]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | Path to the WAV file. |
| **header** | `WavHeader` | — | Parsed WAV header. |
| **num_wavetables** | `Int` | `1` | Number of wavetables per channel. If > 1, splits samples into multiple wavetables of equal size (for large files). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List` <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_sample</span>

<div style="margin-left:3em;" markdown="1">

 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
get_sample(file_data: List[UInt8], offset: Int, bits_per_sample: Int, is_pcm: Bool, is_float: Bool) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_data** | `List` | — | — |
| **offset** | `Int` | — | — |
| **bits_per_sample** | `Int` | — | — |
| **is_pcm** | `Bool` | — | — |
| **is_float** | `Bool` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">read_wav_SIMDs</span>

<div style="margin-left:3em;" markdown="1">

Read all audio samples from s WAV file and return them as a List of SIMD vectors.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
read_wav_SIMDs[num_channels: Int](file_name: String, header: WavHeader, num_wavetables: Int = 1) -> List[SIMD[DType.float64, num_channels]]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_channels** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | Path to the WAV file. |
| **header** | `WavHeader` | — | Parsed WAV header. |
| **num_wavetables** | `Int` | `1` | If > 1, split samples into multiple wavetables of equal size (for large files). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List` <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">print_wav_info</span>

<div style="margin-left:3em;" markdown="1">

Pretty print WAV header information.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
print_wav_info(header: WavHeader)
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **header** | `WavHeader` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">print_sample_stats</span>

<div style="margin-left:3em;" markdown="1">

Print statistics about the audio samples.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
print_sample_stats(samples: List[List[Float64]])
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **samples** | `List` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_f32</span>

<div style="margin-left:3em;" markdown="1">

Write a Float32 as 4 little-endian bytes.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
write_f32(mut data: List[UInt8], value: Float32)
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `List` | — | — |
| **value** | `Float32` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_wav_file</span>

<div style="margin-left:3em;" markdown="1">

Write audio samples to a WAV file.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
write_wav_file(file_name: String, samples: List[List[Float64]], sample_rate: Int = 44100)
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | — |
| **samples** | `List` | — | — |
| **sample_rate** | `Int` | `44100` | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

 <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>

<div style="border-top: 2px solid #247fffff; margin: 20px 0;"></div>


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">write_wav_file</span>

<div style="margin-left:3em;" markdown="1">

Write audio samples to a WAV file.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
write_wav_file[num_channels: Int](file_name: String, samples: List[SIMD[DType.float64, num_channels]], sample_rate: Int = 44100)
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_channels** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **file_name** | `String` | — | — |
| **samples** | `List` | — | — |
| **sample_rate** | `Int` | `44100` | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

 <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
