

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMWorld</span>
**The MMMWorld struct holds global audio processing parameters and state.**

<!-- DESCRIPTION -->
In pretty much all usage, don't edit this struct.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMWorld</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMWorld</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initializes the MMMWorld struct.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sample_rate: Float64 = 48000, block_size: Int = 64, num_in_chans: Int = 2, num_out_chans: Int = 2, osc_buffers_ptr: UnsafePointer[OscBuffers, MutExternalOrigin] = UnsafePointer[True, OscBuffers, MutExternalOrigin, AddressSpace.GENERIC](), windows_ptr: UnsafePointer[Windows, MutExternalOrigin] = UnsafePointer[True, Windows, MutExternalOrigin, AddressSpace.GENERIC](), messenger_manager_ptr: UnsafePointer[MessengerManager, MutExternalOrigin] = UnsafePointer[True, MessengerManager, MutExternalOrigin, AddressSpace.GENERIC]())
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sample_rate** | `Float64` | `48000` | The audio sample rate. |
| **block_size** | `Int` | `64` | The audio block size. |
| **num_in_chans** | `Int` | `2` | The number of input channels. |
| **num_out_chans** | `Int` | `2` | The number of output channels. |
| **osc_buffers_ptr** | `UnsafePointer` | `UnsafePointer[True, OscBuffers, MutExternalOrigin, AddressSpace.GENERIC]()` | A pointer to the OscBuffers struct, which holds precomputed oscillator waveforms. |
| **windows_ptr** | `UnsafePointer` | `UnsafePointer[True, Windows, MutExternalOrigin, AddressSpace.GENERIC]()` | A pointer to the Windows struct, which holds precomputed window functions. |
| **messenger_manager_ptr** | `UnsafePointer` | `UnsafePointer[True, MessengerManager, MutExternalOrigin, AddressSpace.GENERIC]()` | A pointer to the MessengerManager struct. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMWorld</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span>

<div style="margin-left:3em;" markdown="1">

Sets the number of input and output channels.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span> **Signature**  

```mojo
set_channel_count(mut self, num_in_chans: Int, num_out_chans: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_channel_count</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_in_chans** | `Int` | — | The number of input channels. |
| **num_out_chans** | `Int` | — | The number of output channels. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MMMWorld</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">print</span>

<div style="margin-left:3em;" markdown="1">

Print values to the console at the top of the audio block every n_blocks.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">print</span> **Signature**  

```mojo
print[*Ts: Writable](self, *values: *Ts, *, n_blocks: UInt16 = 10, sep: StringSlice[StaticConstantOrigin] = " ", end: StringSlice[StaticConstantOrigin] = "\n")
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">print</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| ***Ts** | `Writable` | — | Types of the values to print. Can be of any type that implements Mojo's `Writable` trait. This parameter is inferred by the values passed to the function. The user doesn't need to specify it. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">print</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| ***values** | `*Ts` | — | Values to print. Can be of any type that implements Mojo's `Writable` trait. This is a "variadic" argument meaning that the user can pass in any number of values (not as a list, just as comma separated arguments). |
| **n_blocks** | `UInt16` | `10` | Number of audio blocks between prints. Must be specified using the keyword argument. |
| **sep** | `StringSlice` | `" "` | Separator string between values. Must be specified using the keyword argument. |
| **end** | `StringSlice` | `"\n"` | End string to print after all values. Must be specified using the keyword argument. |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Interp</span>
**Interpolation types for use in various UGens.**

<!-- DESCRIPTION -->
Specify an interpolation type by typing it explicitly.
For example, to specify linear interpolation, one could use the number `1`, 
but it is clearer to type `Interp.linear`.

| Interpolation Type | Value | Notes                                        |
| ------------------ | ----- | -------------------------------------------- |
| Interp.none        | 0     |                                              |
| Interp.linear      | 1     |                                              |
| Interp.quad        | 2     |                                              |
| Interp.cubic       | 3     |                                              |
| Interp.lagrange4   | 4     |                                              |
| Interp.sinc        | 5     | Should only be used with oscillators         |


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `ImplicitlyDestructible`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->

 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">WindowType</span>
**Window types for predefined windows found in world[].windows.**

<!-- DESCRIPTION -->
Specify a window type by typing it explicitly.
For example, to specify a hann window, one could use the number `1`, 
but it is clearer to type `WindowType.hann`.

| Window Type         | Value |
| ------------------- | ----- |
| WindowType.rect     | 0     |
| WindowType.hann     | 1     |
| WindowType.hamming  | 2     |
| WindowType.blackman | 3     |
| WindowType.kaiser   | 4     |
| WindowType.sine     | 5     |
| WindowType.tri      | 6     |
| WindowType.pan2     | 7     |


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `ImplicitlyDestructible`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->

 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">OscType</span>
**Oscillator types for selecting waveform types.**

<!-- DESCRIPTION -->
Specify an oscillator type by typing it explicitly.
For example, to specify a sine, one could use the number `0`, 
but it is clearer to type `OscType.sine`.

| Oscillator Type              | Value |
| ---------------------------- | ----- |
| OscType.sine                 | 0     |
| OscType.triangle             | 1     |
| OscType.saw                  | 2     |
| OscType.square               | 3     |


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `ImplicitlyDestructible`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->

 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
