

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Play</span>
**The principle buffer playback object for MMMAudio.**

<!-- DESCRIPTION -->
Plays back audio from a Buffer with variable rate, interpolation, looping, and triggering capabilities.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `Representable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Play</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Play</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: pointer to the MMMWorld instance.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Play</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Get the next sample from a SIMD audio buf (SIMDBuffer). The internal phasor is advanced according to the specified rate. If a trigger is received, playback starts at the specified start_frame. If looping is enabled, playback will loop back to the start when reaching the end of the specified num_frames. A key difference between SIMDBuffer and Buffer is that calling next on a SIMDBuffer always returns the entire SIMD vector of samples for the current phase, whereas with Buffer, you can specify the number of channels to read.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[num_chans: Int = 1, interp: Int = Interp.linear, bWrap: Bool = False](mut self, buf: SIMDBuffer[num_chans], rate: Float64 = 1, loop: Bool = True, trig: Bool = True, start_frame: Int = 0, var num_frames: Int = -1) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of output channels to read from the buffer and also the size of the output SIMD vector. |
| **interp** | `Int` | `Interp.linear` | Interpolation method to use when reading from the buffer (see the Interp struct for available options - default: Interp.linear). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). This is necessary when reading from a wavetable or other oscillating buffer, for instance, where the ending samples of the buffer connect seamlessly to the first. If this is false, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buf** | `SIMDBuffer` | — | The audio buf to read from (List[MFloat[num_chans]]). |
| **rate** | `Float64` | `1` | The playback rate. 1 is the normal speed of the buf. |
| **loop** | `Bool` | `True` | Whether to loop the buf (default: True). |
| **trig** | `Bool` | `True` | Trigger starts the synth at start_frame (default: 1.0). |
| **start_frame** | `Int` | `0` | The start frame for playback (default: 0) upon receiving a trigger. |
| **num_frames** | `Int` | `-1` | The end frame for playback (default: -1 means to the end of the buf). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample(s) from the buf as a SIMD vector.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Play</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Get the next sample from an audio buf (Buffer). The internal phasor is advanced according to the specified rate. If a trigger is received, playback starts at the specified start_frame. If looping is enabled, playback will loop back to the start when reaching the end of the specified num_frames.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[num_chans: Int = 1, interp: Int = Interp.linear, bWrap: Bool = False](mut self, buf: Buffer, rate: Float64 = 1, loop: Bool = True, trig: Bool = True, start_frame: Int = 0, var num_frames: Int = -1, start_chan: Int = 0) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of output channels to read from the buffer and also the size of the output SIMD vector. |
| **interp** | `Int` | `Interp.linear` | Interpolation method to use when reading from the buffer (see the Interp struct for available options - default: Interp.linear). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). This is necessary when reading from a wavetable or other oscillating buffer, for instance, where the ending samples of the buffer connect seamlessly to the first. If this is false, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buf** | `Buffer` | — | The audio buf to read from (List[Float64]). |
| **rate** | `Float64` | `1` | The playback rate. 1 is the normal speed of the buf. |
| **loop** | `Bool` | `True` | Whether to loop the buf (default: True). |
| **trig** | `Bool` | `True` | Trigger starts the synth at start_frame (default: 1.0). |
| **start_frame** | `Int` | `0` | The start frame for playback (default: 0) upon receiving a trigger. |
| **num_frames** | `Int` | `-1` | The end frame for playback (default: -1 means to the end of the buf). |
| **start_chan** | `Int` | `0` | The start channel for multi-channel bufs (default: 0). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
The next sample(s) from the buf as a SIMD vector.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Play</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_relative_phase</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_relative_phase</span> **Signature**  

```mojo
get_relative_phase(mut self) -> Float64
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_relative_phase</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span>
**A single grain for granular synthesis.**

<!-- DESCRIPTION -->
Used as part of the TGrains and the PitchShift structs for triggered granular synthesis.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`, `PolyObject`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">check_active</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">check_active</span> **Signature**  

```mojo
check_active(mut self) -> Bool
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">check_active</span> **Returns**
: `Bool` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_trigger</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_trigger</span> **Signature**  

```mojo
set_trigger(mut self, trigger: Bool)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_trigger</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **trigger** | `Bool` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan2</span>

<div style="margin-left:3em;" markdown="1">

Generate the next grain and pan it to stereo using pan2. Depending on num_playback_chans, will either pan a mono signal out 2 channels using pan2 or a stereo signal out 2 channels using pan_stereo.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan2</span> **Signature**  

```mojo
next_pan2[num_playback_chans: Int = 1, win_type: Int = 0, bWrap: Bool = False](mut self, mut buffer: SIMDBuffer[num_chans], rate: Float64 = 1, loop: Bool = False, start_frame: Int = 0, duration: Float64 = 0, pan: Float64 = 0, gain: Float64 = 1) -> SIMD[DType.float64, 2]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan2</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_playback_chans** | `Int` | `1` | Either 1 or 2, depending on whether you want to pan 1 channel of a buffer out 2 channels or 2 channels of the buffer with equal power panning. |
| **win_type** | `Int` | `0` | Type of window to apply to the grain (default is Hann window (WinType.hann)). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). When False, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan2</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `SIMDBuffer` | — | Audio buffer containing the source sound. |
| **rate** | `Float64` | `1` | Playback rate of the grain (1.0 = normal speed). |
| **loop** | `Bool` | `False` | Whether to loop the grain (default: False). |
| **start_frame** | `Int` | `0` | Starting frame position in the buffer. |
| **duration** | `Float64` | `0` | Duration of the grain in seconds. |
| **pan** | `Float64` | `0` | Panning position from -1.0 (left) to 1.0 (right). |
| **gain** | `Float64` | `1` | Amplitude scaling factor for the grain. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan2</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span>

<div style="margin-left:3em;" markdown="1">

Generate the next grain and pan it to N speakers using azimuth panning.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Signature**  

```mojo
next_pan_az[num_simd_chans: Int = 4, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: SIMDBuffer[num_chans], rate: Float64 = 1, loop: Bool = False, start_frame: Int = 0, duration: Float64 = 0, buffer_chan: Int = 0, pan: Float64 = 0, gain: Float64 = 1, num_speakers: Int = 4) -> SIMD[DType.float64, num_simd_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_simd_chans** | `Int` | `4` | Number of output channels (speakers). Must be a power of two that is at least as large as num_speakers. |
| **win_type** | `Int` | `WindowType.hann` | Type of window to apply to the grain (default is Hann window (WindowType.hann) See [WindowType](MMMWorld.md/#struct-windowtype) for all options.). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). When False, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `SIMDBuffer` | — | Audio buffer containing the source sound. |
| **rate** | `Float64` | `1` | Playback rate of the grain (1.0 = normal speed). |
| **loop** | `Bool` | `False` | Whether to loop the grain (default: False). |
| **start_frame** | `Int` | `0` | Starting frame position in the buffer. |
| **duration** | `Float64` | `0` | Duration of the grain in seconds. |
| **buffer_chan** | `Int` | `0` | The buffer channel to read from for the grain (default: 0). |
| **pan** | `Float64` | `0` | Panning position from 0.0 to 1.0. |
| **gain** | `Float64` | `1` | Amplitude scaling factor for the grain. |
| **num_speakers** | `Int` | `4` | Number of speakers to pan to. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Grain</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next unpanned grain. This is called internally by the panning functions, but can also be used directly if panning is not needed. The grain will always have the channel size of the SIMDBuffer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[num_chans: Int = 1, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: SIMDBuffer[num_chans], rate: Float64 = 1, loop: Bool = False, start_frame: Int = 0, duration: Float64 = 0, pan: Float64 = 0, gain: Float64 = 1) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of output channels to read from the buffer and also the size of the output SIMD vector. |
| **win_type** | `Int` | `WindowType.hann` | Type of window to apply to the grain (default is Hann window (WinType.hann)). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). When False, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `SIMDBuffer` | — | Audio buffer containing the source sound. |
| **rate** | `Float64` | `1` | Playback rate of the grain (1.0 = normal speed). |
| **loop** | `Bool` | `False` | Whether to loop the grain (default: False). |
| **start_frame** | `Int` | `0` | Starting frame position in the buffer. |
| **duration** | `Float64` | `0` | Duration of the grain in seconds. |
| **pan** | `Float64` | `0` | Panning position from -1.0 (left) to 1.0 (right). |
| **gain** | `Float64` | `1` | Amplitude scaling factor for the grain. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">TGrains</span>
**Triggered granular synthesis. Each trigger starts a new grain.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">TGrains</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">TGrains</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     num_grains: Number of grains to initialize.     max_grains: Maximum number of grains that can be allocated.     world: Pointer to the MMMWorld instance.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, num_grains: Int, max_grains: Int, world: UnsafePointer[MMMWorld, MutExternalOrigin])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_grains** | `Int` | — | — |
| **max_grains** | `Int` | — | — |
| **world** | `UnsafePointer` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">TGrains</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next set of grains. Uses pan2 to pan to 2 channels. Depending on num_playback_chans, will either pan a mono signal out 2 channels or a stereo signal out 2 channels.
Args:.
    buffer: Audio buffer containing the source sound.
    rate: Playback rate of the grains (1.0 = normal speed).
    trig: Trigger signal (>0 to start a new grain).
    start_frame: Starting frame position in the buffer.
    duration: Duration of each grain in seconds.
    buf_chan: Channel in the buffer to read from.
    pan: Panning position from -1.0 (left) to 1.0 (right).
    gain: Amplitude scaling factor for the grains.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[num_playback_chans: Int = 1, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: SIMDBuffer[num_chans], rate: Float64 = 1, trig: Bool = False, start_frame: Int = 0, duration: Float64 = 0.10000000000000001, buf_chan: Int = 0, pan: Float64 = 0, gain: Float64 = 1) -> SIMD[DType.float64, 2]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_playback_chans** | `Int` | `1` | Either 1 or 2, depending on whether you want to pan 1 channel of a buffer out 2 channels or 2 channels of the buffer with equal power panning. |
| **win_type** | `Int` | `WindowType.hann` | Type of window to apply to each grain (default is Hann window (WinType.hann)). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). When False, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `SIMDBuffer` | — | — |
| **rate** | `Float64` | `1` | — |
| **trig** | `Bool` | `False` | — |
| **start_frame** | `Int` | `0` | — |
| **duration** | `Float64` | `0.10000000000000001` | — |
| **buf_chan** | `Int` | `0` | — |
| **pan** | `Float64` | `0` | — |
| **gain** | `Float64` | `1` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD`
List of output samples for all channels.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">TGrains</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span>

<div style="margin-left:3em;" markdown="1">

Generate the next set of grains. Uses azimuth panning for N channel output.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Signature**  

```mojo
next_pan_az[num_simd_chans: Int = 2, win_type: Int = WindowType.hann, bWrap: Bool = False](mut self, mut buffer: SIMDBuffer[num_chans], rate: Float64 = 1, trig: Bool = False, start_frame: Int = 0, duration: Float64 = 0.10000000000000001, buf_chan: Int = 0, pan: Float64 = 0, gain: Float64 = 1, num_speakers: Int = 2) -> SIMD[DType.float64, num_simd_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_simd_chans** | `Int` | `2` | The size of the output SIMD vector. Must be a power of two that is at least as large as num_speakers. |
| **win_type** | `Int` | `WindowType.hann` | Type of window to apply to each grain (default is Hann window (WinType.hann)). |
| **bWrap** | `Bool` | `False` | Whether to interpolate between the end and start of the buffer when reading (default: False). When False, reading beyond the end of the buffer will return 0. When True, the index into the buffer will wrap around to the beginning using a modulus. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **buffer** | `SIMDBuffer` | — | Audio buffer containing the source sound. |
| **rate** | `Float64` | `1` | Playback rate of the grains (1.0 = normal speed). |
| **trig** | `Bool` | `False` | Trigger signal (>0 to start a new grain). |
| **start_frame** | `Int` | `0` | Starting frame position in the buffer. |
| **duration** | `Float64` | `0.10000000000000001` | Duration of each grain in seconds. |
| **buf_chan** | `Int` | `0` | Channel in the buffer to read from. |
| **pan** | `Float64` | `0` | Panning position from -1.0 (left) to 1.0 (right). |
| **gain** | `Float64` | `1` | Amplitude scaling factor for the grains. |
| **num_speakers** | `Int` | `2` | Number of speakers to pan to. Must be fewer than or equal to num_simd_chans. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_pan_az</span> **Returns**
: `SIMD`
Output samples for all channels as a SIMD vector.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PitchShift</span>
**An N channel granular pitchshifter. Each channel is processed in parallel.**

<!-- DESCRIPTION -->
Args:
    world: Pointer to the MMMWorld instance.
    buf_dur: Duration of the internal buffer in seconds.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PitchShift</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Number of input/output channels. |
| **win_type** | `Int` | `WindowType.hann` | Type of window to apply to each grain (default is Hann window (WinType.hann)). |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PitchShift</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PitchShift</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     world: pointer to the MMMWorld instance.     overlaps: Number of overlapping grains (default is 4).     buf_dur: duration of the internal buffer in seconds.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], buf_dur: Float64 = 2, num_grains: Int = 6, max_grains: Int = 12)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | — |
| **buf_dur** | `Float64` | `2` | — |
| **num_grains** | `Int` | `6` | — |
| **max_grains** | `Int` | `12` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PitchShift</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Generate the next set of grains for pitch shifting.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, in_sig: SIMD[DType.float64, num_chans], grain_dur: Float64 = 0.20000000000000001, overlaps: Int = 4, pitch_ratio: Float64 = 1, pitch_dispersion: Float64 = 0, time_dispersion: Float64 = 0, added_delay_low: Float64 = 0, added_delay_high: Float64 = 0, gain: Float64 = 1) -> SIMD[DType.float64, num_chans]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **in_sig** | `SIMD` | — | Input signal to be pitch shifted. |
| **grain_dur** | `Float64` | `0.20000000000000001` | Duration of each grain in seconds. |
| **overlaps** | `Int` | `4` | Number of overlapping grains (default is 4). |
| **pitch_ratio** | `Float64` | `1` | Pitch shift ratio (1.0 = no shift, 2.0 = one octave up, 0.5 = one octave down, etc). |
| **pitch_dispersion** | `Float64` | `0` | Amount of random variation in pitch ratio. |
| **time_dispersion** | `Float64` | `0` | Amount of random variation in grain triggering time. Value between 0.0 and 1.0, where 0.0 is no variation and 1.0 is maximum variation of up to the grain duration. |
| **added_delay_low** | `Float64` | `0` | Minimum amount of delay to add to the start of each grain in seconds. |
| **added_delay_high** | `Float64` | `0` | Maximum amount of delay to add to the start of each grain in seconds. (Maximum added delay should be set so that it does not exceed the internal buffer size when combined with the grain duration and time dispersion). |
| **gain** | `Float64` | `1` | Amplitude scaling factor for the output. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
