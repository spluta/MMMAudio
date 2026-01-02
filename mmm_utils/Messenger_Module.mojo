from mmm_src.MMMWorld_Module import *
from collections import Dict, Set

struct Messenger(Copyable, Movable):
    """Messenger is a struct to enable communication between Python and Mojo.
    
    It works by checking for messages sent from Python at the start of each audio block, and updating
    any parameters registered with it accordingly. Each data type has its own `update` function and `notify_update` which will return a Bool indicating whether the parameter was updated.

    For example, to update a Float64 parameter from Python, first register it with the Messenger in Mojo:

    ```mojo
    # in the init function
    self.messenger = Messenger(self.world)
    self.freq = 440.0

    # in the next function
    messenger.update(self.freq, "freq")
    ```
    Then from Python, send a new value for 'freq' using the `send_float` function:

    ```python
    mmm_audio.send_float('freq', 880.0)
    ```

    If you want to know whether the parameter was updated, use `notify_update` instead:

    ```mojo 
    if messenger.notify_update(self.freq, "freq"):
        print("Frequency updated to ", freq)
    ```
    """

    var namespace: Optional[String]
    var world: UnsafePointer[MMMWorld]

    var key_dict: Dict[String, String]

    fn __init__(out self, world: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        """Initialize the Messenger.

        If a 'namespace' is provided, any messages sent from Python need to be prepended with this name.
        For example, if a Float64 is registered with this Messenger as 'freq' and this Messenger has the
        namespace 'synth1', then to update the freq value from Python, the user must send:

        ```python
        mmm_audio.send_float('synth1.freq',440.0)
        ```

        For example usage, see the [TODO] file in 'Examples.'

        Args:
            world: An `UnsafePointer[MMMWorld]` to the world to check for new messages.
            namespace: A `String` (or by defaut `None`) to declare as the 'namespace' for this Messenger.

        Returns:
            None
        """

        self.world = world
        self.namespace = namespace
        self.key_dict = Dict[String, String]()

    @doc_private
    fn get_name_with_namespace(mut self, name: String) raises -> UnsafePointer[String]:
        if not self.key_dict.__contains__(name):
            if self.namespace:
                with_namespace = self.namespace.value()+"."+name
            else:
                with_namespace = name
            print("adding long name: ", with_namespace)
            self.key_dict[name] = with_namespace

        return UnsafePointer(to=self.key_dict[name])

    # update Bool
    fn update(mut self, mut param: Bool, name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_bool(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating bool message. Error: ", error)

    # notify_update Bool
    fn notify_update(mut self, mut param: Bool, name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_bool(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
                    return True
            except error:
                print("Error occurred while updating bool message. Error: ", error)
        return False

    # update List[Bool]
    # fn update(mut self, mut param: List[Bool], name: String):
    #     if self.world[].top_of_block:
    #         try:
    #             var opt = self.world[].messengerManager.get_bools(self.get_name_with_namespace(name)[])
    #             if opt:
    #                 param = opt.value().copy()
    #         except error:
    #             print("Error occurred while updating bool message. Error: ", error)

    # # notify_update List[Bool]
    # fn notify_update(mut self, mut param: List[Bool], name: String) -> Bool:
    #     if self.world[].top_of_block:
    #         try:
    #             var opt = self.world[].messengerManager.get_bools(self.get_name_with_namespace(name)[])
    #             if opt:
    #                 param = opt.value().copy()
    #                 return True
    #         except error:
    #             print("Error occurred while updating bool message. Error: ", error)
    #     return False

    # update Float64
    fn update(mut self, mut param: Float64, name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_float(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating float message. Error: ", error)

    # notify_update Float64
    fn notify_update(mut self, mut param: Float64, name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_float(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
                    return True
            except error:
                print("Error occurred while updating float message. Error: ", error)
        return False

    # update List[Float64]
    fn update(mut self, mut param: List[Float64], ref name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_floats(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
            except error:
                print("Error occurred while updating float list message. Error: ", error)

    # notify_update List[Float64]
    fn notify_update(mut self, mut param: List[Float64], ref name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_floats(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
                    return True
            except error:
                print("Error occurred while updating float list message. Error: ", error)
        return False

    fn update(mut self, mut param: SIMD[DType.float64], name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_floats(self.get_name_with_namespace(name)[])
                if opt:
                    for i in range(len(opt.value())):
                        param[i] = opt.value()[i]
            except error:
                print("Error occurred while updating float SIMD message. Error: ", error)

    fn notify_update(mut self, mut param: SIMD[DType.float64], name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_floats(self.get_name_with_namespace(name)[])
                if opt:
                    for i in range(len(opt.value())):
                        param[i] = opt.value()[i]
                    return True
            except error:
                print("Error occurred while updating float SIMD message. Error: ", error)
        return False

    # update Int64
    fn update(mut self, mut param: Int64, name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_int(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating int message. Error: ", error)

    # notify_update Int64
    fn notify_update(mut self, mut param: Int64, name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_int(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
                    return True
            except error:
                print("Error occurred while updating int message. Error: ", error)
        return False

    # update List[Int64]
    fn update(mut self, mut param: List[Int64], ref name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_ints(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
                    return True
            except error:
                print("Error occurred while updating int list message. Error: ", error)
        return False

    # notify_update List[Int64]
    fn notify_update(mut self, mut param: List[Int64], ref name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_ints(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
                    return True
            except error:
                print("Error occurred while updating int list message. Error: ", error)
        return False

    # update String
    fn update(mut self, mut param: String, name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_string(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating text message. Error: ", error)

    # notify_update String
    fn notify_update(mut self, mut param: String, name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_string(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
                    return True
            except error:
                print("Error occurred while updating text message. Error: ", error)
        return False

    # update List[String]
    fn update(mut self, mut param: List[String], name: String):
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_strings(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
            except error:
                print("Error occurred while updating text message. Error: ", error)
    
    # notify_update List[String]
    fn notify_update(mut self, mut param: List[String], name: String) -> Bool:
        if self.world[].top_of_block:
            try:
                var opt = self.world[].messengerManager.get_strings(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
                    return True
            except error:
                print("Error occurred while updating text message. Error: ", error)
        return False

    # # update Trig
    # fn update(mut self, mut param: Trig, name: String):
    #     if self.world[].top_of_block or self.world[].block_state == 1:
    #         try:
    #             param.state = self.world[].messengerManager.get_trig(self.get_name_with_namespace(name)[])
    #         except error:
    #             print("Error occurred while updating trig message. Error: ", error)

    # notify_update Trig
    # fn notify_update(mut self, mut param: Trig, name: String) -> Bool:
    #     if self.world[].top_of_block:
    #         try:
    #             param.state = self.world[].messengerManager.get_trig(self.get_name_with_namespace(name)[])
    #             return param.state
    #         except error:
    #             print("Error occurred while updating trig message. Error: ", error)
    #     return False

    fn notify_trig(mut self, name: String) -> Bool:
        """Get notified if a `send_trig` message was sent under the specified name.

        For examples usage see: "ChowningFM.mojo" and "In2Out.mojo" in the 'Examples' folder.

        Args:
            name: A `String` to identify the trigger sent from Python.

        Returns:
            A `Bool` indicating whether a trigger was sent from Python under the specified name
        """

        # Old Documentation, to be added back in if Trig is added back in:
        # ================================================================
        # Often a trigger is only needed as a boolean flag to indicate that it has
        # been sent from Python, without needing to store the actual Trig object. `notify_trig`
        # provides a convenient way to check for this. No Trig or Bool object is needed. This only
        # works for a single trigger (not `send_trigs`). Because a Bool (what is returned here) is 
        # a primitive type, it 
        # can operate in register on the CPU, potentially providing better performance than Trig.

        if self.world[].top_of_block:
            try:
                return self.world[].messengerManager.get_trig(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while updating trig message. Error: ", error)
        return False

    # update List[Trig]
    # fn update(mut self, mut param: List[Trig], name: String):
    #     if self.world[].top_of_block:
    #         try:
    #             var opt = self.world[].messengerManager.get_trigs(self.get_name_with_namespace(name)[])
    #             if opt:
    #                 param = [Trig(v) for v in opt.value()]
    #         except error:
    #             print("Error occurred while updating trig message. Error: ", error)
    #     elif self.world[].block_state == 1:
    #         for ref t in param:
    #             t.state = False

    # notify_update List[Trig]
    # fn notify_update(mut self, mut param: List[Trig], name: String) -> Bool:
    #     if self.world[].top_of_block:
    #         try:
    #             var opt = self.world[].messengerManager.get_trigs(self.get_name_with_namespace(name)[])
    #             if opt:
    #                 param = [Trig(v) for v in opt.value()]
    #                 return True
    #         except error:
    #             print("Error occurred while updating trig message. Error: ", error)
    #     elif self.world[].block_state == 1:
    #         for ref t in param:
    #             t.state = False
    #     return False

# struct Trig(Representable, Writable, Boolable, Copyable, Movable, ImplicitlyBoolable):
#     """A 'Trigger' that can be controlled from Python.

#     It is either True (triggered) or False (not triggered). 
#     It works like a boolean in all places, but different from a boolean it can be
#     registered with a Messenger under a user specified name. 
    
#     It only make sense to use Trig if it is registered with a Messenger. Otherwise 
#     you can just use a Bool directly.
    
#     The Messenger checks for any
#     'triggers' sent under the specified name at the start of each audio block, and sets
#     the Trig's state accordingly. If there is a trigger under the name, this Trig
#     will be True for 1 sample (the first of the audio block), and then automatically reset to
#     False for the rest of the block.

#     For an usage example, see the [TODO] file in 'Examples.'
#     """
#     var state: Bool

#     fn __init__(out self, starting_state: Bool = False):
#         """Initialize the Trig with an optional starting state. 
        
#         If the starting
#         state is set to True, this Trig will be true for the first sample of the
#         first audio block and then go down to False on the very next sample. This might be
#         useful for initializing some process at the beginning of the audio thread, but note
#         that many processes look for a *change* from low to high, so if this Trig starts 
#         high it might not trigger as expected.
#         """
#         self.state = starting_state

#     @doc_private
#     fn __as_bool__(self) -> Bool:
#         return self.state
    
#     @doc_private
#     fn __bool__(self) -> Bool:
#         return self.state

#     @doc_private
#     fn __repr__(self) -> String:
#         return String(self.state)

#     @doc_private
#     fn write_to(self, mut writer: Some[Writer]):
#         writer.write(self.state)

@doc_private
struct BoolMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Bool

    fn __init__(out self, value: Bool):
        self.retrieved = False
        self.value = value

@doc_private
struct BoolsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Bool]

    fn __init__(out self, value: List[Bool]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct FloatMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Float64

    fn __init__(out self, value: Float64):
        self.retrieved = False
        self.value = value

@doc_private
struct FloatsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Float64]

    fn __init__(out self, value: List[Float64]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct IntMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Int64

    fn __init__(out self, value: Int64):
        self.retrieved = False
        self.value = value

@doc_private
struct IntsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Int64]

    fn __init__(out self, value: List[Int64]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct StringMessage(Movable, Copyable):
    var value: String
    var retrieved: Bool

    fn __init__(out self, value: String):
        self.value = value.copy()
        self.retrieved = False

@doc_private
struct StringsMessage(Movable, Copyable):
    var value: List[String]
    var retrieved: Bool

    fn __init__(out self, value: List[String]):
        self.value = value.copy()
        self.retrieved = False

# struct TrigMessage isn't necessary. See MessengerManager for explanation.

@doc_private
struct TrigsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Bool]

    fn __init__(out self, value: List[Bool]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct MessengerManager(Movable, Copyable):

    var bool_msg_pool: Dict[String, Bool]
    var bool_msgs: Dict[String, BoolMessage]

    var bools_msg_pool: Dict[String, List[Bool]]
    var bools_msgs: Dict[String, BoolsMessage]

    var float_msg_pool: Dict[String, Float64]
    var float_msgs: Dict[String, FloatMessage]
    
    var floats_msg_pool: Dict[String, List[Float64]]
    var floats_msgs: Dict[String, FloatsMessage]
    
    var int_msg_pool: Dict[String, Int64]
    var int_msgs: Dict[String, IntMessage]

    var ints_msg_pool: Dict[String, List[Int64]]
    var ints_msgs: Dict[String, IntsMessage]

    var string_msg_pool: Dict[String, String]
    var string_msgs: Dict[String, StringMessage]

    var strings_msg_pool: Dict[String, List[String]]
    var strings_msgs: Dict[String, StringsMessage]

    var trig_msg_pool: Set[String]
    # Rather than making a TrigMessage struct, we only need a Dict:
    # Keys are the "trig names" that have been pooled, the Bools are
    # whether or not they were retrieved this block.
    var trig_msgs: Dict[String, Bool]

    var trigs_msg_pool: Dict[String, List[Bool]]
    var trigs_msgs: Dict[String, TrigsMessage]
    
    fn __init__(out self):

        self.bool_msg_pool = Dict[String, Bool]()
        self.bool_msgs = Dict[String, BoolMessage]()

        self.bools_msg_pool = Dict[String, List[Bool]]()
        self.bools_msgs = Dict[String, BoolsMessage]()

        self.float_msg_pool = Dict[String, Float64]()
        self.float_msgs = Dict[String, FloatMessage]()

        self.floats_msg_pool = Dict[String, List[Float64]]()
        self.floats_msgs = Dict[String, FloatsMessage]()

        self.int_msg_pool = Dict[String, Int64]()
        self.int_msgs = Dict[String, IntMessage]()
        
        self.ints_msg_pool = Dict[String, List[Int64]]()
        self.ints_msgs = Dict[String, IntsMessage]()

        self.string_msg_pool = Dict[String, String]()
        self.string_msgs = Dict[String, StringMessage]()

        self.strings_msg_pool = Dict[String, List[String]]()
        self.strings_msgs = Dict[String, StringsMessage]()

        self.trig_msg_pool = Set[String]()
        self.trig_msgs = Dict[String, Bool]()

        self.trigs_msg_pool = Dict[String, List[Bool]]()
        self.trigs_msgs = Dict[String, TrigsMessage]()

    ##### Bool #####
    @always_inline
    fn update_bool_msg(mut self, key: String, value: Bool):
        self.bool_msg_pool[key] = value

    @always_inline
    fn update_bools_msg(mut self, key: String, var value: List[Bool]):
        self.bools_msg_pool[key] = value^

    ##### Float #####
    @always_inline
    fn update_float_msg(mut self, key: String, value: Float64):
        self.float_msg_pool[key] = value

    @always_inline
    fn update_floats_msg(mut self, key: String, var value: List[Float64]):
        self.floats_msg_pool[key] = value^

    ##### Int #####
    @always_inline
    fn update_int_msg(mut self, key: String, value: Int64):
        self.int_msg_pool[key] = value
    
    @always_inline
    fn update_ints_msg(mut self, key: String, var value: List[Int64]):
        self.ints_msg_pool[key] = value^

    ##### String #####
    @always_inline
    fn update_string_msg(mut self, key: String, value: String):
        self.string_msg_pool[key] = value

    @always_inline
    fn update_strings_msg(mut self, key: String, var value: List[String]):
        self.strings_msg_pool[key] = value^

    ##### Trig #####
    @always_inline
    fn update_trig_msg(mut self, var key: String):
        self.trig_msg_pool.add(key^)

    @always_inline
    fn update_trigs_msg(mut self, key: String, var value: List[Bool]):
        self.trigs_msg_pool[key] = value^

    fn transfer_msgs(mut self) raises:

        for bm in self.bool_msg_pool.take_items():
            self.bool_msgs[bm.key] = BoolMessage(bm.value)

        for bsm in self.bools_msg_pool.take_items():
            self.bools_msgs[bsm.key] = BoolsMessage(bsm.value)

        for fm in self.float_msg_pool.take_items():
            self.float_msgs[fm.key] = FloatMessage(fm.value)

        for fsm in self.floats_msg_pool.take_items():
            self.floats_msgs[fsm.key] = FloatsMessage(fsm.value)

        for im in self.int_msg_pool.take_items():
            self.int_msgs[im.key] = IntMessage(im.value)

        for ism in self.ints_msg_pool.take_items():
            self.ints_msgs[ism.key] = IntsMessage(ism.value)

        for sm in self.string_msg_pool.take_items():
            self.string_msgs[sm.key] = StringMessage(sm.value)

        for ssm in self.strings_msg_pool.take_items():
            self.strings_msgs[ssm.key] = StringsMessage(ssm.value)

        for tm in self.trig_msg_pool:
            self.trig_msgs[tm] = False  # Set retrieved Bool to False initially
        # The other pools are Dicts so "take_items()" empties them, but since
        # trig_msg_pool is a Set, we have to clear it manually:
        self.trig_msg_pool.clear() 

        for tsm in self.trigs_msg_pool.take_items():
            self.trigs_msgs[tsm.key] = TrigsMessage(tsm.value)

    # get_* functions retrieve messages from the Dicts *after* they have
    # been transferred from the pools to the Dicts. These functions are called
    # from a graph (likely via a Messenger instance) to get the latest message values.
    @always_inline
    fn get_bool(mut self, ref key: String) raises -> Optional[Bool]:
        if key in self.bool_msgs:
            self.bool_msgs[key].retrieved = True
            return self.bool_msgs[key].value
        return None

    @always_inline
    fn get_bools(mut self: Self, ref key: String) raises-> Optional[List[Bool]]:
        if key in self.bools_msgs:
            self.bools_msgs[key].retrieved = True
            # Copy is ok here because it will only copy when there is a
            # new list for it to use, which should be rare. If the user
            # is, like, streaming lists of tons of values, they should
            # be using a different method, such as loading the data into
            # a buffer ahead of time and reading from that.
            return self.bools_msgs[key].value.copy()
        return None
    
    @always_inline
    fn get_float(mut self, ref key: String) raises -> Optional[Float64]:
        if key in self.float_msgs:
            self.float_msgs[key].retrieved = True
            return self.float_msgs[key].value
        return None

    @always_inline
    fn get_floats(mut self: Self, ref key: String) raises-> Optional[List[Float64]]:
        if key in self.floats_msgs:
            self.floats_msgs[key].retrieved = True
            # Copy is ok here because it will only copy when there is a
            # new list for it to use, which should be rare. If the user
            # is, like, streaming lists of tons of values, they should
            # be using a different method, such as loading the data into
            # a buffer ahead of time and reading from that.
            return self.floats_msgs[key].value.copy()
        return None

    @always_inline
    fn get_int(mut self, ref key: String) raises -> Optional[Int64]:
        if key in self.int_msgs:
            self.int_msgs[key].retrieved = True
            return self.int_msgs[key].value
        return None

    @always_inline
    fn get_ints(mut self, ref key: String) raises -> Optional[List[Int64]]:
        if key in self.ints_msgs:
            self.ints_msgs[key].retrieved = True
            return self.ints_msgs[key].value.copy()
        return None

    @always_inline
    fn get_string(mut self, ref key: String) raises -> Optional[String]:
        if key in self.string_msgs:
            self.string_msgs[key].retrieved = True
            return self.string_msgs[key].value
        return None

    @always_inline
    fn get_strings(mut self, ref key: String) raises -> Optional[List[String]]:
        if key in self.strings_msgs:
            self.strings_msgs[key].retrieved = True
            return self.strings_msgs[key].value.copy()
        return None

    @always_inline
    fn get_trig(mut self, key: String) -> Bool:
        if key in self.trig_msgs:
            self.trig_msgs[key] = True
            return True
        return False

    @always_inline
    fn get_trigs(mut self, key: String) raises -> Optional[List[Bool]]:
        if key in self.trigs_msgs:
            self.trigs_msgs[key].retrieved = True
            return self.trigs_msgs[key].value.copy()
        return None

    fn empty_msg_dicts(mut self):
        for bool_msg in self.bool_msgs.take_items():
            if not bool_msg.value.retrieved:
                print("Bool message was not retrieved this block:", bool_msg.key)

        for bools_msg in self.bools_msgs.take_items():
            if not bools_msg.value.retrieved:
                print("Bools message was not retrieved this block:", bools_msg.key)

        for float_msg in self.float_msgs.take_items():
            if not float_msg.value.retrieved:
                print("Float message was not retrieved this block:", float_msg.key)

        for floats_msg in self.floats_msgs.take_items():
            if not floats_msg.value.retrieved:
                print("Floats message was not retrieved this block:", floats_msg.key)

        for int_msg in self.int_msgs.take_items():
            if not int_msg.value.retrieved:
                print("Int message was not retrieved this block:", int_msg.key)

        for ints_msg in self.ints_msgs.take_items():
            if not ints_msg.value.retrieved:
                print("Ints message was not retrieved this block:", ints_msg.key)

        for string_msg in self.string_msgs.take_items():
            if not string_msg.value.retrieved:
                print("String message was not retrieved this block:", string_msg.key)
        
        for strings_msg in self.strings_msgs.take_items():
            if not strings_msg.value.retrieved:
                print("Strings message was not retrieved this block:", strings_msg.key)

        for tm in self.trig_msgs.take_items():
            if not tm.value:
                print("Trig message was not retrieved this block:", tm.key)

        for trigs_msg in self.trigs_msgs.take_items():
            if not trigs_msg.value.retrieved:
                print("Trigs message was not retrieved this block:", trigs_msg.key)
