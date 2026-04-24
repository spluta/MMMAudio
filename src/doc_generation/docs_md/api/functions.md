

<!-- TRAITS -->

<!-- STRUCTS -->

<!-- FUNCTIONS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #247fffff; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Functions
</div>
(Functions that are not associated with a Struct)


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">dbamp</span>

<div style="margin-left:3em;" markdown="1">

Converts decibel values to amplitude.
 <!-- endif overload.summary -->

amplitude = 10^(dB/20).

 <!-- end if overload.description -->

**Signature**

```mojo
dbamp[width: Int, //](db: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **width** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **db** | `SIMD` | — | The decibel values to convert. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The corresponding amplitude values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">ampdb</span>

<div style="margin-left:3em;" markdown="1">

Converts amplitude values to decibels.
 <!-- endif overload.summary -->

dB = 20 * log10(amplitude).

 <!-- end if overload.description -->

**Signature**

```mojo
ampdb[width: Int, //](amp: SIMD[DType.float64, width]) -> SIMD[DType.float64, width]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **width** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **amp** | `SIMD` | — | The amplitude values to convert. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The corresponding decibel values.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">power_to_db</span>

<div style="margin-left:3em;" markdown="1">

Convert a power value to decibels.
 <!-- endif overload.summary -->

This mirrors librosa's power_to_db behavior for a single scalar: 10 * log10(max(amin, value) / zero_db_ref).

 <!-- end if overload.description -->

**Signature**

```mojo
power_to_db(value: Float64, zero_db_ref: Float64 = 1, amin: Float64 = 1.0E-10) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **value** | `Float64` | — | Power value to convert. |
| **zero_db_ref** | `Float64` | `1` | Reference power for 0 dB. |
| **amin** | `Float64` | `1.0E-10` | Minimum value to avoid log of zero. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64`
The value in decibels.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">select</span>

<div style="margin-left:3em;" markdown="1">

Selects a value from a SIMD vector based on a floating-point index and using linear interpolation.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
select[num_chans: Int, //](index: Float64, vals: SIMD[DType.float64, num_chans]) -> Float64
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **index** | `Float64` | — | The floating-point index to select. |
| **vals** | `SIMD` | — | The SIMD vector containing the values. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64`
The selected value.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>

<div style="border-top: 2px solid #247fffff; margin: 20px 0;"></div>


## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">select</span>

<div style="margin-left:3em;" markdown="1">

Selects a SIMD vector from a List of SIMD vectors based on a floating-point index using linear interpolation.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
select[num_chans: Int](index: Float64, vals: List[SIMD[DType.float64, num_chans]]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **index** | `Float64` | — | The floating-point index to select. |
| **vals** | `List` | — | The List of SIMD vectors containing the values. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The selected value.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">check_reversed</span>

<div style="margin-left:3em;" markdown="1">

 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
check_reversed[dtype: DType, num_chans: Int](in_min: SIMD[dtype, num_chans], in_max: SIMD[dtype, num_chans]) -> Tuple[SIMD[dtype, num_chans], SIMD[dtype, num_chans], SIMD[DType.bool, num_chans]]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | — |
| **num_chans** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **in_min** | `SIMD` | — | — |
| **in_max** | `SIMD` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Tuple` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">linlin</span>

<div style="margin-left:3em;" markdown="1">

Maps samples from one range to another range linearly.
 <!-- endif overload.summary -->

Samples outside the input range are clamped to the corresponding output boundaries.

 <!-- end if overload.description -->

**Signature**

```mojo
linlin[dtype: DType, num_chans: Int, //](input: SIMD[dtype, num_chans], in_min: SIMD[dtype, num_chans] = 0, in_max: SIMD[dtype, num_chans] = 1, out_min: SIMD[dtype, num_chans] = 0, out_max: SIMD[dtype, num_chans] = 1) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The samples to map. |
| **in_min** | `SIMD` | `0` | The minimum of the input range. |
| **in_max** | `SIMD` | `1` | The maximum of the input range. |
| **out_min** | `SIMD` | `0` | The minimum of the output range. |
| **out_max** | `SIMD` | `1` | The maximum of the output range. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">expexp</span>

<div style="margin-left:3em;" markdown="1">

Exponential-to-exponential transform.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
expexp[num_chans: Int, //](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | Input value to transform (exponential scale). |
| **in_min** | `SIMD` | — | Minimum of input range (exponential). |
| **in_max** | `SIMD` | — | Maximum of input range (exponential). |
| **out_min** | `SIMD` | — | Minimum of output range (exponential). |
| **out_max** | `SIMD` | — | Maximum of output range (exponential). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Exponentially scaled output value.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">linexp</span>

<div style="margin-left:3em;" markdown="1">

Maps samples from one linear range to another exponential range.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
linexp[num_chans: Int, //](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | — |
| **in_min** | `SIMD` | — | — |
| **in_max** | `SIMD` | — | — |
| **out_min** | `SIMD` | — | — |
| **out_max** | `SIMD` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">explin</span>

<div style="margin-left:3em;" markdown="1">

Exponential-to-linear transform (inverse of linexp).
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
explin[num_chans: Int, //](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | Input value to transform (exponential scale). |
| **in_min** | `SIMD` | — | Minimum of input range (exponential). |
| **in_max** | `SIMD` | — | Maximum of input range (exponential). |
| **out_min** | `SIMD` | — | Minimum of output range (linear). |
| **out_max** | `SIMD` | — | Maximum of output range (linear). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Linearly scaled output value
 <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lincurve</span>

<div style="margin-left:3em;" markdown="1">

Maps samples from one linear range to another curved range.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
lincurve[num_chans: Int, //](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans], curve: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector - defaults to 1. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The samples to map. |
| **in_min** | `SIMD` | — | The minimum of the input range. |
| **in_max** | `SIMD` | — | The maximum of the input range. |
| **out_min** | `SIMD` | — | The minimum of the output range (must be > 0). |
| **out_max** | `SIMD` | — | The maximum of the output range (must be > 0). |
| **curve** | `SIMD` | — | The curve factor. Positive values create an exponential-like curve, negative values create a logarithmic-like curve, and zero results in a linear mapping. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The curved mapped samples in the output range.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">curvelin</span>

<div style="margin-left:3em;" markdown="1">

Curve-to-linear transform (inverse of lincurve).
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
curvelin[num_chans: Int, //](input: SIMD[DType.float64, num_chans], in_min: SIMD[DType.float64, num_chans], in_max: SIMD[DType.float64, num_chans], out_min: SIMD[DType.float64, num_chans], out_max: SIMD[DType.float64, num_chans], curve: SIMD[DType.float64, num_chans] = 0) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | Input value to transform (from curved space). |
| **in_min** | `SIMD` | — | Minimum of input range (curved). |
| **in_max** | `SIMD` | — | Maximum of input range (curved). |
| **out_min** | `SIMD` | — | Minimum of output range (linear). |
| **out_max** | `SIMD` | — | Maximum of output range (linear). |
| **curve** | `SIMD` | `0` | Curve parameter (-10 to 10 typical range)
       curve = 0: linear
       curve > 0: undoes exponential curve
       curve < 0: undoes logarithmic curve. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Linearized output value.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">py_to_float64</span>

<div style="margin-left:3em;" markdown="1">

 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
py_to_float64(py_float: PythonObject) -> Float64
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **py_float** | `PythonObject` | — | — |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `Float64` <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">clip</span>

<div style="margin-left:3em;" markdown="1">

Clips each element in the SIMD vector to the specified range.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
clip[dtype: DType, num_chans: Int, //](x: SIMD[dtype, num_chans], lo: SIMD[dtype, num_chans], hi: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **x** | `SIMD` | — | The SIMD vector to clip. Each element will be clipped individually. |
| **lo** | `SIMD` | — | The minimum possible value. |
| **hi** | `SIMD` | — | The maximum possible value. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The clipped SIMD vector.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">wrap</span>

<div style="margin-left:3em;" markdown="1">

Wraps a sample around a specified range.
 <!-- endif overload.summary -->

The wrapped sample within the range [min_val, max_val). 
This function uses modulus arithmetic so the output can never equal max_val.
Returns the sample if min_val >= max_val.

 <!-- end if overload.description -->

**Signature**

```mojo
wrap[dtype: DType, num_chans: Int, //](input: SIMD[dtype, num_chans], min_val: SIMD[dtype, num_chans], max_val: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **input** | `SIMD` | — | The sample to wrap. |
| **min_val** | `SIMD` | — | The minimum of the range. |
| **max_val** | `SIMD` | — | The maximum of the range. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The wrapped value.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">quadratic_interp</span>

<div style="margin-left:3em;" markdown="1">

Performs quadratic interpolation between three points.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
quadratic_interp[dtype: DType, num_chans: Int, //](y0: SIMD[dtype, num_chans], y1: SIMD[dtype, num_chans], y2: SIMD[dtype, num_chans], x: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **y0** | `SIMD` | — | The sample at position 0. |
| **y1** | `SIMD` | — | The sample at position 1. |
| **y2** | `SIMD` | — | The sample at position 2. |
| **x** | `SIMD` | — | The interpolation position (fractional part between 0 and 1). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The interpolated sample at position x.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">cubic_interp</span>

<div style="margin-left:3em;" markdown="1">

Performs cubic interpolation.
 <!-- endif overload.summary -->

Cubic Intepolation equation from *The Audio Programming Book* 
by Richard Boulanger and Victor Lazzarini. pg. 400

 <!-- end if overload.description -->

**Signature**

```mojo
cubic_interp[dtype: DType, num_chans: Int, //](p0: SIMD[dtype, num_chans], p1: SIMD[dtype, num_chans], p2: SIMD[dtype, num_chans], p3: SIMD[dtype, num_chans], t: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **p0** | `SIMD` | — | Point to the left of p1. |
| **p1** | `SIMD` | — | Point to the left of the float t. |
| **p2** | `SIMD` | — | Point to the right of the float t. |
| **p3** | `SIMD` | — | Point to the right of p2. |
| **t** | `SIMD` | — | Interpolation parameter (fractional part between p1 and p2). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Interpolated sample.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">lagrange4</span>

<div style="margin-left:3em;" markdown="1">

Perform Lagrange interpolation for 4th order case (from JOS Faust Model). This is extrapolated from the JOS Faust filter model.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
lagrange4[dtype: DType, num_chans: Int, //](sample0: SIMD[dtype, num_chans], sample1: SIMD[dtype, num_chans], sample2: SIMD[dtype, num_chans], sample3: SIMD[dtype, num_chans], sample4: SIMD[dtype, num_chans], frac: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **sample0** | `SIMD` | — | The first sample. |
| **sample1** | `SIMD` | — | The second sample. |
| **sample2** | `SIMD` | — | The third sample. |
| **sample3** | `SIMD` | — | The fourth sample. |
| **sample4** | `SIMD` | — | The fifth sample. |
| **frac** | `SIMD` | — | The fractional part between sample0 and sample1. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The interpolated sample.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">linear_interp</span>

<div style="margin-left:3em;" markdown="1">

Performs linear interpolation between two points.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
linear_interp[dtype: DType, num_chans: Int, //](p0: SIMD[dtype, num_chans], p1: SIMD[dtype, num_chans], t: SIMD[dtype, num_chans]) -> SIMD[dtype, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **dtype** | `DType` | The data type of the SIMD vector. This parameter is inferred by the values passed to the function. |
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **p0** | `SIMD` | — | The starting point. |
| **p1** | `SIMD` | — | The ending point. |
| **t** | `SIMD` | — | The interpolation parameter (fractional part between p0 and p1). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The interpolated sample.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">midicps</span>

<div style="margin-left:3em;" markdown="1">

Convert MIDI note numbers to frequencies in Hz.
 <!-- endif overload.summary -->

(cps = "cycles per second")

Conversion happens based on equating the `reference_midi_note` to the `reference_frequency`.
For standard tuning, leave the defaults of MIDI note 69 (A4) and 440.0 Hz.

 <!-- end if overload.description -->

**Signature**

```mojo
midicps[num_chans: Int, //](midi_note_number: SIMD[DType.float64, num_chans], reference_midi_note: Float64 = 69, reference_frequency: Float64 = 440) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **midi_note_number** | `SIMD` | — | The MIDI note number(s) to convert. |
| **reference_midi_note** | `Float64` | `69` | The reference MIDI note number. |
| **reference_frequency** | `Float64` | `440` | The frequency of the reference MIDI note. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
Frequency in Hz.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">cpsmidi</span>

<div style="margin-left:3em;" markdown="1">

Convert frequencies in Hz to MIDI note numbers.
 <!-- endif overload.summary -->

(cps = "cycles per second")

Conversion happens based on equating the `reference_midi_note` to the `reference_frequency`.
For standard tuning, leave the defaults of MIDI note 69 (A4) and 440.0 Hz.

 <!-- end if overload.description -->

**Signature**

```mojo
cpsmidi[num_chans: Int, //](freq: SIMD[DType.float64, num_chans], reference_midi_note: Float64 = 69, reference_frequency: Float64 = 440) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **freq** | `SIMD` | — | The frequency in Hz to convert. |
| **reference_midi_note** | `Float64` | `69` | The reference MIDI note number. |
| **reference_frequency** | `Float64` | `440` | The frequency of the reference MIDI note. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The corresponding MIDI note number.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sanitize</span>

<div style="margin-left:3em;" markdown="1">

Sanitizes a SIMD float64 vector by zeroing out elements that are too large, too small, or NaN.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
sanitize[num_chans: Int, //](mut x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **x** | `SIMD` | — | The SIMD float64 vector to sanitize. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
The sanitized SIMD float64 vector.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">rrand</span>

<div style="margin-left:3em;" markdown="1">

Generates a random float64 sample from a uniform distribution.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
rrand[num_chans: Int = 1](min: SIMD[DType.float64, num_chans], max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **min** | `SIMD` | — | The minimum sample (inclusive). |
| **max** | `SIMD` | — | The maximum sample (inclusive). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">exprand</span>

<div style="margin-left:3em;" markdown="1">

Generates a random float64 sample from an exponential distribution.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
exprand[num_chans: Int](min: SIMD[DType.float64, num_chans], max: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Size of the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **min** | `SIMD` | — | The minimum sample (inclusive). |
| **max** | `SIMD` | — | The maximum sample (inclusive). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD` <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">sign</span>

<div style="margin-left:3em;" markdown="1">

Returns the sign of x: -1 if negative, 1 if positive, and 0 if zero.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
sign[num_chans: Int, //](x: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | Number of channels in the SIMD vector. This parameter is inferred by the values passed to the function. |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **x** | `SIMD` | — | The input SIMD vector. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
A SIMD vector containing the sign of each element in x.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">linspace</span>

<div style="margin-left:3em;" markdown="1">

Create evenly spaced values between start and stop.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
linspace(start: Float64, stop: Float64, num: Int) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **start** | `Float64` | — | The starting value. |
| **stop** | `Float64` | — | The ending value. |
| **num** | `Int` | — | Number of samples to generate. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
A List of Float64 values evenly spaced between start and stop.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">diff</span>

<div style="margin-left:3em;" markdown="1">

Compute differences between consecutive elements.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
diff(arr: List[Float64]) -> List[Float64]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **arr** | `List` | — | Input list of Float64 values. |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
A new list with length len(arr) - 1 containing differences.
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">subtract_outer</span>

<div style="margin-left:3em;" markdown="1">

Compute outer subtraction: a[i] - b[j] for all i, j.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
subtract_outer(a: List[Float64], b: List[Float64]) -> List[List[Float64]]
```

 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **a** | `List` | — | First input list (will be rows). |
| **b** | `List` | — | Second input list (will be columns). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `List`
A 2D list where result[i][j] = a[i] - b[j].
 <!-- endif overload.returns -->

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --><hr style="border: none; border-top: 3px solid #247fffff; margin: 20px 0px;">

## `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">coin</span>

<div style="margin-left:3em;" markdown="1">

Return True with probability p, False otherwise.
 <!-- endif overload.summary -->

 <!-- end if overload.description -->

**Signature**

```mojo
coin[num_chans: Int](p: SIMD[DType.float64, num_chans]) -> SIMD[DType.bool, num_chans]
```

**Parameters**

| Name | Type | Description |
|------|------|-------------|
| **num_chans** | `Int` | — |
<!-- end for param in overload.parameters -->
 <!-- endif overload.parameters -->

**Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **p** | `SIMD` | — | Probability of returning True (between 0 and 1). |
<!--end for arg in overload.args -->
 <!-- endif overload.args -->

**Returns**

**Type**: `SIMD`
True with probability p, False otherwise.
 <!-- endif overload.returns -->

**Raises**

 <!-- endif overload.raises -->

 <!-- endif overload.constraints -->


</div>


 <!-- endfor overload in function.overloads --> <!-- endfor function in decl.functions -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
