

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span>

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the audio engine with sample rate, block size, and number of channels.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sample_rate: Float64 = 44100, block_size: Int = 512, num_in_chans: Int = 12, num_out_chans: Int = 12)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sample_rate** | `Float64` | `44100` | — |
| **block_size** | `Int` | `512` | — |
| **num_in_chans** | `Int` | `12` | — |
| **num_out_chans** | `Int` | `12` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">py_init</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">py_init</span> **Signature**  

```mojo
py_init(args: PythonObject, kwargs: PythonObject, out self: Self)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">py_init</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **args** | `PythonObject` | — | — |
| **kwargs** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">py_init</span> **Returns**
: `Self` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span> **Signature**  

```mojo
set_channel_count(py_selfA: PythonObject, args: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **args** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_screen_dims</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_screen_dims</span> **Signature**  

```mojo
set_screen_dims(py_selfA: PythonObject, dims: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_screen_dims</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **dims** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_screen_dims</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_mouse_pos</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_mouse_pos</span> **Signature**  

```mojo
update_mouse_pos(py_selfA: PythonObject, pos: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_mouse_pos</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **pos** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_mouse_pos</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">to_float64</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">to_float64</span> **Signature**  

```mojo
to_float64(py_float: PythonObject) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">to_float64</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_float** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">to_float64</span> **Returns**
: `Float64` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bool_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bool_msg</span> **Signature**  

```mojo
update_bool_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bool_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bool_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bools_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bools_msg</span> **Signature**  

```mojo
update_bools_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bools_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_bools_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_float_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_float_msg</span> **Signature**  

```mojo
update_float_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_float_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_float_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_floats_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_floats_msg</span> **Signature**  

```mojo
update_floats_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_floats_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_floats_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_int_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_int_msg</span> **Signature**  

```mojo
update_int_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_int_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_int_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_ints_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_ints_msg</span> **Signature**  

```mojo
update_ints_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_ints_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_ints_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trig_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trig_msg</span> **Signature**  

```mojo
update_trig_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trig_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trig_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trigs_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trigs_msg</span> **Signature**  

```mojo
update_trigs_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trigs_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_trigs_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_string_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_string_msg</span> **Signature**  

```mojo
update_string_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_string_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_string_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_strings_msg</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_strings_msg</span> **Signature**  

```mojo
update_strings_msg(py_selfA: PythonObject, key_vals: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_strings_msg</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **key_vals** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update_strings_msg</span> **Returns**
: `PythonObject` 

**Raises**



<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_audio_samples</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_audio_samples</span> **Signature**  

```mojo
get_audio_samples(mut self, loc_in_buffer: UnsafePointer[Float32, origin], mut loc_out_buffer: UnsafePointer[Float64, origin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_audio_samples</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **loc_in_buffer** | `UnsafePointer` | — | — |
| **loc_out_buffer** | `UnsafePointer` | — | — |


**Raises**



<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMAudioBridge</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(py_selfA: PythonObject, in_buffer: PythonObject, out_buffer: PythonObject) -> PythonObject
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_selfA** | `PythonObject` | — | — |
| **in_buffer** | `PythonObject` | — | — |
| **out_buffer** | `PythonObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `PythonObject` 

**Raises**



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


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PyInit_MMMAudioBridge</span>

<div style="margin-left:3em;" markdown="1">

 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
PyInit_MMMAudioBridge() -> PythonObject
```

 <!-- endif overload.parameters -->

 <!-- endif overload.args -->

**Returns**

**Type**: `PythonObject` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
