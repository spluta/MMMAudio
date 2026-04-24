

<!-- TRAITS -->

<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span>
**Communication between Python and Mojo.**

<!-- DESCRIPTION -->
It works by checking for messages sent from Python at the start of each audio block, and updating
any parameters registered with it accordingly. Each data type has its own `update` function and `notify_update` which will return a Bool indicating whether the parameter was updated.

For example usage, see the MessengerExample.mojo file in the [Examples](../examples/index.md) folder.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Initialize the Messenger.
If a 'namespace' is provided, any messages sent from Python need to be prepended with this name.
For example, if a Float64 updates with the name 'freq' and this Messenger has the
namespace 'synth1', then to update the freq value from Python, the user must send 'synth1.freq'.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, world: UnsafePointer[MMMWorld, MutExternalOrigin], namespace: Optional[String] = None)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **world** | `UnsafePointer` | — | An `World` to the world to check for new messages. |
| **namespace** | `Optional` | `None` | A `String` (or by defaut `None`) to declare as the 'namespace' for this Messenger. If a 'namespace' is provided, any messages sent from Python need to be prepended with this name. For example, if a Float64 updates with the name 'freq' and this Messenger has the namespace 'synth1', then to update the freq value from Python, the user must send 'synth1.freq'. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a Bool variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: Bool, name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `Bool` | — | A `Bool` variable to be updated. |
| **name** | `String` | — | A `String` to identify the Bool sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a Float64 variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: Float64, name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `Float64` | — | A `Float64` variable to be updated. |
| **name** | `String` | — | A `String` to identify the Float64 sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a List[Float64] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: List[Float64], ref name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `List` | — | A `List[Float64]` variable to be updated. The List will be resized to match the incoming data. |
| **name** | `String` | — | A `String` to identify the List[Float64] sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a SIMD[DType.float64] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: SIMD[DType.float64, size], name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `SIMD` | — | A `SIMD[DType.float64]` variable to be updated. The SIMD will *not* be resized to match the incoming data. It is the user's responsibility to ensure the sizes match. |
| **name** | `String` | — | A `String` to identify the SIMD[DType.float64] sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a Int variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: Int, name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `Int` | — | A `Int` variable to be updated. |
| **name** | `String` | — | A `String` to identify the Int sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a List[Int] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: List[Int], ref name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `List` | — | A `List[Int]` variable to be updated. The List will be resized to match the incoming data. |
| **name** | `String` | — | A `String` to identify the List[Int] sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a String variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: String, name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `String` | — | A `String` variable to be updated. |
| **name** | `String` | — | A `String` to identify the String sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span>

<div style="margin-left:3em;" markdown="1">

Update a List[String] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Signature**  

```mojo
update(mut self, mut param: List[String], name: String)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `List` | — | A `List[String]` variable to be updated. The List will be resized to match the incoming data. |
| **name** | `String` | — | A `String` to identify the List[String] sent from Python. |





<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a Bool variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: Bool, name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `Bool` | — | A `Bool` variable to be updated. |
| **name** | `String` | — | A `String` to identify the Bool sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a Float64 variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: Float64, name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `Float64` | — | A `Float64` variable to be updated. |
| **name** | `String` | — | A `String` to identify the Float64 sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a List[Float64] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: List[Float64], ref name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `List` | — | A `List[Float64]` variable to be updated. The List will be resized to match the incoming data. |
| **name** | `String` | — | A `String` to identify the List[Float64] sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a SIMD[DType.float64] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: SIMD[DType.float64, size], name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `SIMD` | — | A `SIMD[DType.float64]` variable to be updated. The SIMD will *not* be resized to match the incoming data. It is the user's responsibility to ensure the sizes match. |
| **name** | `String` | — | A `String` to identify the SIMD[DType.float64] sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a Int variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: Int, name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `Int` | — | A `Int` variable to be updated. |
| **name** | `String` | — | A `String` to identify the Int sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a List[Int] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: List[Int], ref name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `List` | — | A `List[Int]` variable to be updated. The List will be resized to match the incoming data. |
| **name** | `String` | — | A `String` to identify the List[Int] sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a String variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: String, name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `String` | — | A `String` variable to be updated. |
| **name** | `String` | — | A `String` to identify the String sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span>

<div style="margin-left:3em;" markdown="1">

Notify and update a List[String] variable with a value sent from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Signature**  

```mojo
notify_update(mut self, mut param: List[String], name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **param** | `List` | — | A `List[String]` variable to be updated. The List will be resized to match the incoming data. |
| **name** | `String` | — | A `String` to identify the List[String] sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_update</span> **Returns**
: `Bool`
A `Bool` indicating whether the parameter was updated.
 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">Messenger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_trig</span>

<div style="margin-left:3em;" markdown="1">

Get notified if a `send_trig` message was sent under the specified name.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_trig</span> **Signature**  

```mojo
notify_trig(mut self, name: String) -> Bool
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_trig</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **name** | `String` | — | A `String` to identify the trigger sent from Python. |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">notify_trig</span> **Returns**
: `Bool`
A `Bool` indicating whether a trigger was sent from Python under the specified name.
 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
