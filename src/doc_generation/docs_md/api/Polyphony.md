

<!-- TRAITS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #9333EA; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Traits
</div>

## trait <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyObject</span>





### <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyObject</span> Required Methods

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyObject</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">check_active</span>

A required, user defind function to check if the voice is active. This is usually done by checking if the envelope is active or if a Play object is still playing. This function is used internally by Poly to keep track of which voices are active and which are not.


**Signature**

```mojo
check_active(mut self: _Self) -> Bool
```



**Returns**

**Type**: `Bool`

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyObject</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_trigger</span>

Necessary for triggered PolyObjects. This function is used internally by Poly to set the PolyObject to triggered. That way, the PolyObject can open its own envelope or trigger other parameters in the subsequent `next` call.


**Signature**

```mojo
set_trigger(mut self: _Self, trigger: Bool)
```


**Arguments**

- **trigger**: `Bool`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyObject</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">set_gate</span>

Necessary for gated PolyObjects. This function is used internally by PolyGate and PolyGateSig to open and close the gate of the PolyObject.


**Signature**

```mojo
set_gate(mut self: _Self, gate: Bool)
```


**Arguments**

- **gate**: `Bool`

!!! info "Default Implementation"
    This method has a default implementation.

---

#### `trait` <span style="color: #9333EA; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyObject</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">reset_env</span>

Necessary for gated PolyObjects that use gated envelopes. This is needed because Poly will internally copy a living PolyObject to create a new voice, and this can result in a hung voice if the env is already active when it's copied.


**Signature**

```mojo
reset_env(mut self: _Self)
```




!!! info "Default Implementation"
    This method has a default implementation.

---




<!-- STRUCTS -->

<div style="font-size: 2.6rem; font-weight: 800; text-transform: uppercase; letter-spacing: 0.06em; color: #0f172a; border-bottom: 5px solid #E04738; padding-bottom: 0.35rem; margin: 48px 0 24px;">
Structs
</div>



## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span>
**A Poly implementation that has an internal Messenger for handling messages from Python. The `next` function is designed to be used with messages that simply trigger a voice. Use PolyGate for messages that open and close gates.**

<!-- DESCRIPTION -->
PolyTrigger is designed to be paired with the PolyPal class in Python. Give them the same name_space and num_messages arguments, and the messages sent from Python with PolyPal will be correctly received by the PolyTrigger object.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, initial_num_voices: Int, max_voices: Int, world: UnsafePointer[MMMWorld, MutExternalOrigin], name_space: String, num_messages: Int = 10)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **initial_num_voices** | `Int` | — | — |
| **max_voices** | `Int` | — | — |
| **world** | `UnsafePointer` | — | — |
| **name_space** | `String` | — | — |
| **num_messages** | `Int` | `10` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

This convenience function acheives all functionality of a Triggered PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and triggers PolyObjects as needed. The optional call_back function is called whenever a new trigger is received from Python. `next` has to be paired with messages sent from Python as a List[Int] or a List[Float64] or an Int or a Float64. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn(mut poly_object: T, mut vals: List[Int]) -> None)
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |
| **only_top_of_block** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **call_back** | `fn(mut poly_object: T, mut vals: List[Int]) -> None` | — | — |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn(mut poly_object: T, mut vals: List[Float64]) -> None)
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |
| **only_top_of_block** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **call_back** | `fn(mut poly_object: T, mut vals: List[Float64]) -> None` | — | — |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn(mut poly_object: T, mut val: Int) -> None)
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |
| **only_top_of_block** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **call_back** | `fn(mut poly_object: T, mut val: Int) -> None` | — | — |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTrigger</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn(mut poly_object: T, mut val: Float64) -> None)
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |
| **only_top_of_block** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **call_back** | `fn(mut poly_object: T, mut val: Float64) -> None` | — | — |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGate</span>
**A Poly implementation that has an internal Messenger for handling messages from Python. The `next` function is designed to be used with list messages where the second value opens and closes the voice's gate.**

<!-- DESCRIPTION -->
PolyGate is designed to be paired with the PolyPal class in Python. Give them the same name_space and num_messages arguments, and the messages sent from Python with PolyPal will be correctly received by the PolyGate object.


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGate</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGate</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, initial_num_voices: Int, max_voices: Int, world: UnsafePointer[MMMWorld, MutExternalOrigin], name_space: String, num_messages: Int = 10)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **initial_num_voices** | `Int` | — | — |
| **max_voices** | `Int` | — | — |
| **world** | `UnsafePointer` | — | — |
| **name_space** | `String` | — | — |
| **num_messages** | `Int` | `10` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGate</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

This convenience function acheives all functionality of a Gated PolyObject synth in one function. It resets the Poly at the beginning of each block, looks for triggers from Python, and opens and closes gates for PolyObjects as needed. The call_back function is called whenever a new trigger is received from Python. `next` has to be paired with messages sent from Python as a List[Int] or a List[Float64], where the first value is the note or key to trigger and the second value is the velocity or gate of the note. A 0 in the second value will close the gate. The call_back function receives the List or value as the second argument, so the PolyObject can be controlled by the message from Python.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn(mut poly_object: T, mut vals: List[Int]) -> None)
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |
| **only_top_of_block** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **call_back** | `fn(mut poly_object: T, mut vals: List[Int]) -> None` | — | — |





<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGate</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject, only_top_of_block: Bool = True](mut self, mut poly_objects: List[T], call_back: fn(mut poly_object: T, mut vals: List[Float64]) -> None)
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |
| **only_top_of_block** | `Bool` | `True` | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **call_back** | `fn(mut poly_object: T, mut vals: List[Float64]) -> None` | — | — |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGateSig</span>
**A Poly object designed for managing polyphonic synths with gated controls that are signals.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGateSig</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGateSig</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, initial_num_voices: Int, max_voices: Int, num_gates: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **initial_num_voices** | `Int` | — | — |
| **max_voices** | `Int` | — | — |
| **num_gates** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyGateSig</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

This function is designed to be used with polyphonic synths that have gated controls that are signals.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject](mut self, mut poly_objects: List[T], gate_sigs: List[Bool])
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | A list of structs conforming to the PolyObject trait. This function calls the set_gate function for each PolyObject to open and close the gates as needed. |
| **gate_sigs** | `List` | — | A list of boolean signals that control the gates of the voices. Each signal corresponds to a different gate, so the length of the gate_sigs list should be the same as the number of gates in the synth. When a signal goes from False to True, the corresponding gate will be opened for a new voice. When a signal goes from True to False, the corresponding gate will be closed for the voice that is currently playing with that gate. |





<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->
<div style="border-top: 3px solid #E04738; margin: 20px 0;"></div>


## struct <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTriggerSig</span>
**A Poly implementation for synths triggered by signals, like TGrains and PitchShift.**

<!-- DESCRIPTION -->


<!-- PARENT TRAITS -->
*Traits:* `AnyType`, `Copyable`, `ImplicitlyDestructible`, `Movable`
<!-- PARAMETERS -->

<hr style="border: none; border-top: 2px dotted #e04738; margin: 20px 60px;">

<!-- FUNCTIONS -->
### <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTriggerSig</span> **Functions**



#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTriggerSig</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span>

<div style="margin-left:3em;" markdown="1">

Args:     initial_num_voices (Int): the number of voices to start with. This can be changed later by the Poly object itself if more voices need to be added.     max_voices (Int): the maximum number of voices that can be allocated. Poly will not allocate more than this number of voices.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Signature**  

```mojo
__init__(out self, initial_num_voices: Int, max_voices: Int)
```


`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **initial_num_voices** | `Int` | — | — |
| **max_voices** | `Int` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">__init__</span> **Returns**
: `Self` 




<!-- STATIC METHOD WARNING -->
!!! info "Static Method"
    This is a static method.

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTriggerSig</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">

Looks at the value of trig. If trig is True, looks for a free voice and triggers it. Returns the index of the voice that was triggered, or -1 if no voice was triggered.

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **trig** | `Bool` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `Int` 




<!-- STATIC METHOD WARNING -->

</div>


#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTriggerSig</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Signature**  

```mojo
next[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool, call_back: fn(mut poly_object: T, trig: Bool) -> None) -> Int
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **trig** | `Bool` | — | — |
| **call_back** | `fn(mut poly_object: T, trig: Bool) -> None` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">next</span> **Returns**
: `Int` 




<!-- STATIC METHOD WARNING -->

</div>




#### `struct` <span style="color: #E04738; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">PolyTriggerSig</span> . `fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">find_voice_and_trigger</span>

<div style="margin-left:3em;" markdown="1">



`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">find_voice_and_trigger</span> **Signature**  

```mojo
find_voice_and_trigger[T: PolyObject](mut self, mut poly_objects: List[T], trig: Bool) -> Int
```

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">find_voice_and_trigger</span> **Parameters**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **T** | `PolyObject` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">find_voice_and_trigger</span> **Arguments**

| Name | Type | Default | Description |
|------|------|---------|-------------|
| **poly_objects** | `List` | — | — |
| **trig** | `Bool` | — | — |

`fn` <span style="color: #247fffff; background-color: #e5e7eb; padding: 2px 6px; border-radius: 3px; font-family: monospace;">find_voice_and_trigger</span> **Returns**
: `Int` 




<!-- STATIC METHOD WARNING -->

</div>



 <!-- endif struct.constraints -->

<!-- DEPRECATION WARNING -->

<!-- FUNCTIONS -->
 <!-- endif  decl.functions -->

---

*Documentation generated with `mojo doc` from Mojo version 0.26.1.0*
