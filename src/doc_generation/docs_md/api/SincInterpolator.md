

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SincInterpolator</span>
**Sinc Interpolation of `List[Float64]`s.**

<!-- DESCRIPTION -->
Struct for high-quality audio resampling using sinc interpolation. This struct precomputes a sinc table and provides methods for performing sinc interpolation
on audio data with adjustable ripples and table size. It is used in Osc for resampling oscillator signals.

As a user, you won't need to interact with this struct directly. Instead use the [ListInterpolator](Buffer.md#struct-listinterpolator) struct.



<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SincInterpolator</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **ripples** | `Int` | `4` | Number of ripples in the sinc function, affecting interpolation quality. |
| **power** | `Int` | `14` | Power of two determining the size of the sinc table (table_size = 2^power). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SincInterpolator</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SincInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SincInterpolator</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sinc_interp</span>

<div style="margin-left:3em;" markdown="1">

Perform sinc interpolation on the given data at the specified current index.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sinc_interp</span> **Signature**  

```mojo
sinc_interp[num_chans: Int, bWrap: Bool = True, mask: Int = 0](self, data: Span[SIMD[DType.float64, num_chans], origin], current_index: Float64, prev_index: Float64) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sinc_interp</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | — | The number of channels in the audio data. |
| **bWrap** | `Bool` | `True` | Whether to wrap around at the end of the buffer when an index exceeds the buffer length. |
| **mask** | `Int` | `0` | Mask for wrapping indices if bWrap is True. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sinc_interp</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **data** | `Span` | — | The audio data (Buffer channel) to interpolate. |
| **current_index** | `Float64` | — | The current fractional index for interpolation. |
| **prev_index** | `Float64` | — | The previous index. Needed to calculate the slope. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sinc_interp</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
