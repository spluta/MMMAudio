

<!-- TRAITS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #9333EA; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Traits
</div>

## trait <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">GetFloat64Featurable</span>





### <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">GetFloat64Featurable</span> Required Methods

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">GetFloat64Featurable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>



**Signature**

```mojo
get_features(self: _Self) -> List[Float64]
```



**Returns**

**Type**: `List`

---



## trait <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">GetBoolFeaturable</span>





### <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">GetBoolFeaturable</span> Required Methods

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">GetBoolFeaturable</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>



**Signature**

```mojo
get_features(self: _Self) -> List[Bool]
```



**Returns**

**Type**: `List`

---




<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">YIN</span>
**Monophonic Frequency ('F0') Detection using the YIN algorithm (FFT-based, O(N log N) version).**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `BufferedProcessable`, `Copyable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">YIN</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">YIN</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the YIN pitch detector.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, window_size: Int = 1024, min_freq: Float64 = 20, max_freq: Float64 = 2.0E+4)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **window_size** | `Int` | `1024` | The size of the analysis window in samples. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider for pitch detection. |
| **max_freq** | `Float64` | `2.0E+4` | The maximum frequency to consider for pitch detection. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized YIN struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">YIN</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current pitch and confidence as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">YIN</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span>

<div style="margin-left:3em;" markdown="1">

Compute the YIN pitch estimate for the given frame of audio samples.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span> **Signature**  

```mojo
next_window(mut self, mut frame: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **frame** | `List` | — | The input audio frame of size `window_size`. This List gets passed from [BufferedProcess](BufferedProcess.md). |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCentroid</span>
**Spectral Centroid analysis.**

<!-- DESCRIPTION -->
Based on the [Peeters (2003)](http://recherche.ircam.fr/anasyn/peeters/ARTICLES/Peeters_2003_cuidadoaudiofeatures.pdf)


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCentroid</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCentroid</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Centroid analyzer. Args:     sr: The sample rate from the MMMWorld.     min_freq: The minimum frequency to consider when computing the spectral centroid.     max_freq: The maximum frequency to consider when computing the spectral centroid.     power_mag: Whether to use power magnitudes (mags^2) instead of linear magnitudes when computing the centroid.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized SpectralCentroid struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCentroid</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral centroid value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCentroid</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral centroid for a given FFT analysis.
This function is to be used by FFTProcess if SpectralCentroid is passed as the "process".

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |
| **phases** | `List` | — | The input phases as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCentroid</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral centroid for the given magnitudes of an FFT frame.
This static method is useful when there is an FFT already computed, perhaps as 
part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |
| **sample_rate** | `Float64` | — | The sample rate of the audio signal. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider when computing the spectral centroid. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider when computing the spectral centroid. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2) instead of linear magnitudes when computing the centroid. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64`
Float64. The spectral centroid value.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSpread</span>
**Spectral Spread analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSpread</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSpread</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Spread analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider. |
| **log_freq** | `Bool` | `False` | Whether to use log-frequency (MIDI) bins. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSpread</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral spread value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSpread</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral spread for a given FFT analysis.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **phases** | `List` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSpread</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **sample_rate** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **log_freq** | `Bool` | `False` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSkewness</span>
**Spectral Skewness analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSkewness</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSkewness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Skewness analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider. |
| **log_freq** | `Bool` | `False` | Whether to use log-frequency (MIDI) bins. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSkewness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral skewness value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSkewness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral skewness for a given FFT analysis.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **phases** | `List` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralSkewness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **sample_rate** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **log_freq** | `Bool` | `False` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralKurtosis</span>
**Spectral Kurtosis analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralKurtosis</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralKurtosis</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Kurtosis analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider. |
| **log_freq** | `Bool` | `False` | Whether to use log-frequency (MIDI) bins. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralKurtosis</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral kurtosis value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralKurtosis</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral kurtosis for a given FFT analysis.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **phases** | `List` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralKurtosis</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **sample_rate** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **log_freq** | `Bool` | `False` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralRolloff</span>
**Spectral Rolloff analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralRolloff</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralRolloff</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Rolloff analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, rolloff_target: Float64 = 95, log_freq: Bool = False, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider. |
| **rolloff_target** | `Float64` | `95` | Percentage of spectral energy for rolloff. |
| **log_freq** | `Bool` | `False` | Whether to use log-frequency (MIDI) bins. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralRolloff</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral rolloff value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralRolloff</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral rolloff for a given FFT analysis.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **phases** | `List` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralRolloff</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, rolloff_target: Float64 = 95, log_freq: Bool = False, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **sample_rate** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **rolloff_target** | `Float64` | `95` | — |
| **log_freq** | `Bool` | `False` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlatness</span>
**Spectral Flatness analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlatness</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlatness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Flatness analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider. |
| **log_freq** | `Bool` | `False` | Whether to use log-frequency (MIDI) bins. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlatness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral flatness value (dB) as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlatness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral flatness for a given FFT analysis.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **phases** | `List` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlatness</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **sample_rate** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **log_freq** | `Bool` | `False` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCrest</span>
**Spectral Crest analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCrest</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCrest</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Crest analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **min_freq** | `Float64` | `20` | The minimum frequency to consider. |
| **max_freq** | `Float64` | `20000` | The maximum frequency to consider. |
| **log_freq** | `Bool` | `False` | Whether to use log-frequency (MIDI) bins. |
| **power_mag** | `Bool` | `False` | Whether to use power magnitudes (mags^2). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCrest</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral crest value (dB) as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCrest</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral crest for a given FFT analysis.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **phases** | `List` | — | — |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralCrest</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, log_freq: Bool = False, power_mag: Bool = False) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | — |
| **sample_rate** | `Float64` | — | — |
| **min_freq** | `Float64` | `20` | — |
| **max_freq** | `Float64` | `20000` | — |
| **log_freq** | `Bool` | `False` | — |
| **power_mag** | `Bool` | `False` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RMS</span>
**Root Mean Square (RMS) amplitude analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `BufferedProcessable`, `Copyable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RMS</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RMS</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the RMS analyzer.

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




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RMS</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current RMS value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RMS</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span>

<div style="margin-left:3em;" markdown="1">

Compute the RMS for the given window of audio samples.
This function is to be used with a [BufferedProcess](BufferedProcess.md/#struct-bufferedprocess).

The computed RMS value is stored in self.rms.
`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span> **Signature**  

```mojo
next_window(mut self, mut input: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_window</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `List` | — | The input audio frame of samples. This List gets passed from [BufferedProcess](BufferedProcess.md/#struct-bufferedprocess). |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">RMS</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_window</span>

<div style="margin-left:3em;" markdown="1">

Compute the RMS for the given window of audio samples.
This static method is useful when there is an audio frame already available, perhaps
as part of a custom struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_window</span> **Signature**  

```mojo
from_window(mut frame: List[Float64]) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_window</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **frame** | `List` | — | The input audio frame of samples. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_window</span> **Returns**
: `Float64`
Float64. The computed RMS value.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span>
**Mel Bands analysis.**

<!-- DESCRIPTION -->
This implementation follows the approach used in the [Librosa](https://librosa.org/) library. 

The Mel scale is a perceptual scale of pitches that approximates the human ear's response more closely than the linear frequency scale. Mel Bands analysis involves mapping the FFT frequency bins to the Mel scale and computing the energy in each Mel band. This way the "magnitudes" of each Mel band represent a, roughly, equal amount of perceptual frequency space (unlike the FFT).

Because the definition of the mel scale is conditioned by a finite number
of subjective psychoacoustical experiments, several implementations coexist
in the audio signal processing literature. MMMAudio replicates the default of Librosa, which replicates
the behavior of the well-established MATLAB ["Auditory Toolbox"](https://engineering.purdue.edu/~malcolm/interval/1998-010/) of Slaney (citation below).
According to this implementation,  the conversion from Hertz to mel is
linear below 1 kHz and logarithmic above 1 kHz. Additionally, the weights are normalized such that the area under each mel filter is equal. Slaney mel filter "triangles" all have equal area ([visualization](https://www.youtube.com/watch?v=UCLlVAj0PPY)), which helps to ensure that the energy in each mel band is comparable.

Slaney, M. Auditory Toolbox: A MATLAB Toolbox for Auditory Modeling Work. Technical Report, version 2, Interval Research Corporation, 1998.

<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Mel Bands analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, num_bands: Int = 40, min_freq: Float64 = 20, max_freq: Float64 = 2.0E+4, fft_size: Int = 1024, power: Float64 = 2)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate from the MMMWorld. |
| **num_bands** | `Int` | `40` | The number of mel bands to compute. |
| **min_freq** | `Float64` | `20` | The minimum frequency (in Hz) to consider when computing the mel bands. |
| **max_freq** | `Float64` | `2.0E+4` | The maximum frequency (in Hz) to consider when computing the mel bands. |
| **fft_size** | `Int` | `1024` | The size of the FFT being used to compute the mel bands. |
| **power** | `Float64` | `2` | Exponent applied to magnitudes before mel filtering (librosa default is 2.0 for power). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized MelBands struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current mel band values as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the mel bands for a given FFT analysis.
This function is to be used by FFTProcess if MelBands is passed as the "process".

Nothing is returned from this function, but the computed mel band values are stored in self.bands.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |
| **phases** | `List` | — | The input phases as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">

Compute the mel bands for a given list of magnitudes.
This function is useful when there is an FFT already computed, perhaps as 
part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mut self, ref mags: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_frequencies</span>

<div style="margin-left:3em;" markdown="1">

Compute an array of acoustic frequencies tuned to the mel scale.
This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.mel_frequencies.html).  For more information on mel frequencies space see the [MelBands](Analysis.md/#struct-melbands) documentation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_frequencies</span> **Signature**  

```mojo
mel_frequencies(n_mels: Int = 128, fmin: Float64 = 0, fmax: Float64 = 2.0E+4) -> List[Float64]
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_frequencies</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **n_mels** | `Int` | `128` | The number of mel bands to generate. |
| **fmin** | `Float64` | `0` | The lowest frequency (in Hz). |
| **fmax** | `Float64` | `2.0E+4` | The highest frequency (in Hz). |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_frequencies</span> **Returns**
: `List`
A List of Float64 representing the center frequencies of each mel band.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hz_to_mel</span>

<div style="margin-left:3em;" markdown="1">

Convert Hz to Mels.
This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.hz_to_mel.html). For more information on mel frequencies space see the [MelBands](Analysis.md/#struct-melbands) documentation.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hz_to_mel</span> **Signature**  

```mojo
hz_to_mel[num_chans: Int = 1](freq: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hz_to_mel</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hz_to_mel</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | — | The frequencies in Hz to convert. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">hz_to_mel</span> **Returns**
: `SIMD`
The corresponding mel frequencies.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MelBands</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_to_hz</span>

<div style="margin-left:3em;" markdown="1">

Convert mel bin numbers to frequencies.
This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.mel_to_hz.html). For more information on mel frequencies space see the [MelBands](Analysis.md/#struct-melbands) documentation.
`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_to_hz</span> **Signature**  

```mojo
mel_to_hz[num_chans: Int = 1](mel: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_to_hz</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_to_hz</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mel** | `SIMD` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">mel_to_hz</span> **Returns**
: `SIMD` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span>
**Mel-Frequency Cepstral Coefficients (MFCC) analysis.**

<!-- DESCRIPTION -->

This implementation follows the approach used in the [Librosa](https://librosa.org/) library.

Learn more about MFCCs on the [FluCoMa learn page](https://learn.flucoma.org/reference/mfcc/) and with this [interactive demonstration](https://www.tedmoore.art/mfccs/).

<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the MFCC analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, sr: Float64, num_coeffs: Int = 13, num_bands: Int = 40, min_freq: Float64 = 20, max_freq: Float64 = 2.0E+4, fft_size: Int = 1024)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sr** | `Float64` | — | The sample rate for the mel band computation. |
| **num_coeffs** | `Int` | `13` | The number of MFCC coefficients to compute (including the 0th coefficient). |
| **num_bands** | `Int` | `40` | The number of mel bands to use when computing the MFCCs. |
| **min_freq** | `Float64` | `20` | The minimum frequency (in Hz) to consider when computing the mel bands for the MFCCs. |
| **max_freq** | `Float64` | `2.0E+4` | The maximum frequency (in Hz) to consider when computing the mel bands for the MFCCs. |
| **fft_size** | `Int` | `1024` | The size of the FFT being used to compute the mel bands for the MFCCs. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self`
An initialized MFCC struct.
 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current MFCC values as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the MFCCs for a given FFT analysis.
This function is to be used by [FFTProcess](FFTProcess.md/#struct-fftprocess) if MFCC is passed as the "process".

Nothing is returned from this function, but the computed MFCC values are stored in self.coeffs.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |
| **phases** | `List` | — | The input phases as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">

Compute the MFCCs for a given list of magnitudes.
This function is useful when there is an FFT already computed, 
perhaps as part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

Nothing is returned from this function, but the computed MFCC values are stored in self.coeffs.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mut self, ref mags: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">MFCC</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mel_bands</span>

<div style="margin-left:3em;" markdown="1">

Compute the MFCCs for a given list of mel band energies.
This function is useful when there is a mel band analysis already computed, perhaps as part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

Nothing is returned from this function, but the computed MFCC values are stored in self.coeffs.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mel_bands</span> **Signature**  

```mojo
from_mel_bands(mut self, ref mbands: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mel_bands</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mbands** | `List` | — | The input mel band energies as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCT</span>
**Compute the Discrete Cosine Transform (DCT).**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCT</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, input_size: Int, output_size: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input_size** | `Int` | — | — |
| **output_size** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">DCT</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">process</span>

<div style="margin-left:3em;" markdown="1">

Compute the first `output_size` DCT-II coefficients for `input`.
Nothing is returned from this function, but the computed DCT coefficients are stored in the `output` List passed as an argument.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">process</span> **Signature**  

```mojo
process(mut self, ref input: List[Float64], mut output: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">process</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `List` | — | Input vector of length `input_size`. |
| **output** | `List` | — | Output vector of length `output_size`. |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlux</span>
**Spectral Flux analysis.**

<!-- DESCRIPTION -->
This implementation computes the squared difference between the magnitudes of the current frame and the previous frame, summed across all frequency bins.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `FFTProcessable`, `GetFloat64Featurable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlux</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlux</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Spectral Flux analyzer.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, num_mags: Int, positive_only: Bool = False)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_mags** | `Int` | — | The number of magnitude bins in the input to expect. This is typically the FFT size divided by 2, but could also be the number of mel bands or another spectral summary that produces a list of values. |
| **positive_only** | `Bool` | `False` | Whether to only consider positive differences (increases in energy) when computing the spectral flux. If `False`, spectral flux is the average of squared differences between the magnitudes. If `True`, spectral flux is the average of (non-squared to match FluCoMa) differences between the magnitudes, but negative differences are set to 0. Using `positive_only=True` is a common approach when using spectral flux for onset detection, as onsets are typically characterized by increases in energy. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlux</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral flux onset value for a given FFT analysis.
This function is to be used by [FFTProcess](FFTProcess.md/#struct-fftprocess) if SpectralFluxOnsets is passed as the "process".

Nothing is returned from this function, but the computed spectral flux value is stored in self.flux.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Signature**  

```mojo
next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64])
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next_frame</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |
| **phases** | `List` | — | The input phases as a List of Float64. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlux</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">

Return the current spectral flux value as a List of Float64.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Float64]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFlux</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span>

<div style="margin-left:3em;" markdown="1">

Compute the spectral flux onset value for a given list of magnitudes.
This function is useful when there is an FFT already computed, perhaps as part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

Nothing is returned from this function, but the computed spectral flux value is stored in self.flux.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Signature**  

```mojo
from_mags(mut self, ref mags: List[Float64]) -> Float64
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **mags** | `List` | — | The input magnitudes as a List of Float64. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">from_mags</span> **Returns**
: `Float64` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFluxOnsets</span>
**Spectral Flux Onset analysis.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `GetBoolFeaturable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->
<span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFluxOnsets</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **num_chans** | `Int` | `1` | — |

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFluxOnsets</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFluxOnsets</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], num_mags: Int, window_size: Int = 1024, hop_size: Int = 512, filter_size: Int = 5)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | — |
| **num_mags** | `Int` | — | — |
| **window_size** | `Int` | `1024` | — |
| **hop_size** | `Int` | `512` | — |
| **filter_size** | `Int` | `5` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFluxOnsets</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Signature**  

```mojo
get_features(self) -> List[Bool]
```



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">get_features</span> **Returns**
: `List` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">SpectralFluxOnsets</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next(mut self, input: Float64) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `Float64` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `Bool` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
