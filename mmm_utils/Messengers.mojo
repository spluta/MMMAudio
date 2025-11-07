from mmm_src.MMMWorld import *

struct Messenger(Copyable, Movable):
    """Messenger is a struct to enable communication between Python and Mojo."""

    var namespace: Optional[String]
    var world_ptr: UnsafePointer[MMMWorld]
    var all_keys: Set[String]
    var bool_dict: Dict[String, UnsafePointer[Bool]]
    var trig_dict: Dict[String, UnsafePointer[Trig]]
    var list_dict: Dict[String, UnsafePointer[List[Float64]]]
    var text_dict: Dict[String, UnsafePointer[TextMsg]]
    var float64_dict: Dict[String, UnsafePointer[Float64]]
    var int_dict: Dict[String, UnsafePointer[Int64]]

    var key_dict: Dict[String, String]  # maps short names to full names with namespace

    # @staticmethod
    # fn make_key(namespace: String, name: String) -> String:
    #     """Create a full key name with optional namespace.

    #     Args:
    #         namespace: An optional `String` namespace.
    #         name: The base `String` name.

    #     Returns:
    #         A `String` representing the full key.
    #     """

    #     return namespace + "." + name


    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        """Initialize the Messenger.

        > Currently, 'namespace' doesn't work properly if the different synths that have a `Messenger` are in a `List` or other `collection`.

        If a 'namespace' is provided, any messages sent from Python need to be prepended with this name.
        For example, if a Float64 is registered with this Messenger as 'freq' and this Messenger has the
        namespace 'synth1', then to update the freq value from Python, the user must send:

        ```python
        mmm_audio.send_float('synth1.freq',440.0)
        ```

        For example usage, see the [TODO] file in 'Examples.'

        Args:
            world_ptr: An `UnsafePointer[MMMWorld]` to the world to check for new messages.
            namespace: A `String` (or by defaut `None`) to declare as the 'namespace' for this Messenger.

        Returns:
            None
        """

        self.world_ptr = world_ptr
        self.namespace = namespace
        self.bool_dict = Dict[String, UnsafePointer[Bool]]()
        self.trig_dict = Dict[String, UnsafePointer[Trig]]()
        self.list_dict = Dict[String, UnsafePointer[List[Float64]]]()
        self.text_dict = Dict[String, UnsafePointer[TextMsg]]()
        self.float64_dict = Dict[String, UnsafePointer[Float64]]()
        self.int_dict = Dict[String, UnsafePointer[Int64]]()
        self.all_keys = Set[String]()

        self.key_dict = Dict[String, String]()

    fn update(self) -> None:
        """This function checks the MMMAudioWorld for any new messages that arrived during the last audio
        block. If it finds any, they will be available in the variables registered with the Messenger. This
        function should be called in the Synth's `.next()` function, so it runs every audio sample (it will only *actually* check for messages at the top of each audio block).
        """
        if self.world_ptr[].top_of_block:
            try:
                # This all goes in a try block because all of the get_* functions are
                # marked "raises." They need to because that is required in order to 
                # access non-copies of the values in the message Dicts.
                for ref item in self.bool_dict.items():
                    var opt: Optional[Bool] = self.world_ptr[].messengerManager.get_bool(item.key)
                    if opt:
                        item.value[] = opt.value()
                for ref item in self.trig_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_trig(item.key)
                    if opt:
                        item.value[].state = opt
                for ref item in self.list_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_list(item.key)
                    if opt:
                        item.value[] = opt.value().copy()
                for ref item in self.text_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_text(item.key)
                    if opt:
                        item.value[].strings = opt.value().copy()
                for ref item in self.float64_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_float(item.key)
                    if opt:
                        item.value[] = opt.value()
                for ref item in self.int_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_int(item.key)
                    if opt:
                        item.value[] = opt.value()
            except error:
                print("Error occurred while updating messages. Error: ", error)
        # Clear trig and text messages at the end of the block so that on the very 
        # next sample they are false/empty again. This can't happen "later" because
        # the variables themselves might be (likely are) checked / used every sample!
        elif self.world_ptr[].block_state == 1:
            for ref item in self.trig_dict.items():
                item.value[].state = False
            for ref item in self.text_dict.items():
                item.value[].strings.clear()

    fn get_long_name(mut self, name: String) raises -> UnsafePointer[String]:
        var contains = self.key_dict.__contains__(name)

        if not contains:
            if self.namespace:
                long_name = self.namespace.value()+"."+name
            else:
                long_name = name
            print("adding long name: ", long_name)
            self.key_dict[name] = long_name

        return UnsafePointer(to=self.key_dict[name])

    fn update(mut self, mut param: Float64, name: String) -> None:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_float(self.get_long_name(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating float message. Error: ", error)

    fn update(mut self, mut param: Int64, name: String) -> None:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_int(self.get_long_name(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating int message. Error: ", error)

    fn update(mut self, mut param: List[Float64], ref name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_list(self.get_long_name(name)[])
                if opt:
                    param = opt.value().copy()
                return opt.__bool__()
            except error:
                print("Error occurred while updating float message. Error: ", error)
        return False

    fn update(mut self, mut param: Bool, name: String) -> None:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_bool(self.get_long_name(name)[])
                if opt:
                    param = opt.value()    
            except error:
                print("Error occurred while updating bool message. Error: ", error)

    fn update(mut self, mut param: Trig, name: String) -> None:
        if self.world_ptr[].top_of_block:
            try:
                param.state = self.world_ptr[].messengerManager.get_trig(self.get_long_name(name)[])
            except error:
                print("Error occurred while updating trig message. Error: ", error)

    fn update(mut self, mut param: String, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_text(self.get_long_name(name)[])
                if opt:
                    param = opt.value()[0]
                return opt.__bool__()
            except error:
                print("Error occurred while updating text message. Error: ", error)
        return False

    fn update(mut self, mut param: List[String], name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_text(self.get_long_name(name)[])
                if opt:
                    param = opt.value().copy()
                return opt.__bool__()
            except error:
                print("Error occurred while updating text message. Error: ", error)
        return False

    @doc_private
    fn check_key_collision(mut self, read name: String) -> String:
        fullname = name
        if self.namespace:
            fullname = self.namespace.value() + "." + name
        try:
            if fullname in self.all_keys:
                raise Error("Messenger key collision: The key '" + fullname + "' is already in use.")
            self.all_keys.add(fullname)
            return fullname
        except error:
            return fullname

    fn register(mut self, ref param: Float64, name: String) -> None:
        """Register a `Float64` with this `Messenger` under a specified `name`.  
        
        Note that `.register()` is overloaded for different types.  
        """

        fullname = self.check_key_collision(name)
        self.float64_dict[fullname] = UnsafePointer(to=param)

    fn register(mut self, ref param: Bool, name: String) -> None:
        """Register a `Bool` with this `Messenger` under a specified `name`.  

        Note that `.register()` is overloaded for different types.  
        """

        fullname = self.check_key_collision(name)
        self.bool_dict[fullname] = UnsafePointer(to=param)

    fn register(mut self, ref param: Trig, name: String) -> None:
        """Register a `Trig` with this `Messenger` under a specified `name`.
        
        Note that `.register()` is overloaded for different types.  
        """
        fullname = self.check_key_collision(name)
        self.trig_dict[fullname] = UnsafePointer(to=param)

    fn register(mut self, ref param: List[Float64], name: String) -> None:
        """Register a `List[Float64]` with this `Messenger` under a specified `name`.
        
        Note that `.register()` is overloaded for different types.  
        """
        fullname = self.check_key_collision(name)
        self.list_dict[fullname] = UnsafePointer(to=param)

    fn register(mut self, ref param: TextMsg, name: String) -> None:
        """Register a `TextMsg` with this `Messenger` under a specified `name`.
        
        Note that `.register()` is overloaded for different types.  
        """
        fullname = self.check_key_collision(name)
        self.text_dict[fullname] = UnsafePointer(to=param)

    fn register(mut self, ref param: Int64, name: String) -> None:
        """Register a `Int64` with this `Messenger` under a specified `name`.

        Note that `.register()` is overloaded for different types.
        """
        fullname = self.check_key_collision(name)
        self.int_dict[fullname] = UnsafePointer(to=param)

struct Trig(Representable, Writable, Boolable, Copyable, Movable):
    """A 'Trigger' that can be controlled from Python.

    It is either True (triggered) or False (not triggered). 
    It works like a boolean in all places, but different from a boolean it can be
    registered with a Messenger under a user specified name. 

    It only make sense to use Trig if it is registered with a Messenger. Otherwise
    you can just use a Bool directly.
    
    The Messenger checks for any
    'triggers' sent under the specified name at the start of each audio block, and sets
    the Trig's state accordingly. If there is a trigger under the name, this Trig
    will be True for 1 sample (the first of the audio block), and then automatically reset to
    False for the rest of the block.

    For an usage example, see the [TODO] file in 'Examples.'
    """
    var state: Bool

    fn __init__(out self, starting_state: Bool = False):
        """Initialize the Trig with an optional starting state. 
        
        If the starting
        state is set to True, this Trig will be true for the first sample of the
        first audio block and then go down to False on the very next sample. This might be
        useful for initializing some process at the beginning of the audio thread, but note
        that many processes look for a *change* from low to high, so if this Trig starts 
        high it might not trigger as expected.
        """
        self.state = starting_state

    @doc_private
    fn __as_bool__(self) -> Bool:
        return self.state
    
    @doc_private
    fn __bool__(self) -> Bool:
        return self.state

    @doc_private
    fn __repr__(self) -> String:
        return String(self.state)

    @doc_private
    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.state)

struct TextMsg(Representable, Writable, Sized, Copyable, Movable):
    """A 'Text' message that can be sent from Python. 
    
    It is essentially a list of strings.
    It only makes sense to use TextMsg if it is registered with a Messenger.

    It works like a List[String] in all places, but different from a List[String] it can be
    registered with a Messenger under a user specified name. This is a list rather than a single string
    because it might be necessary to send multiple pieces of information at once, for example a lot of buffers
    to load.

    When sending a message from Python, send one at a time.
    ```python
    mmm_audio.send_text("load_buffer","path/to/sound1.wav")
    mmm_audio.send_text("load_buffer","path/to/sound2.wav")
    ```

    As these messages are received in Mojo, any that arrive within the same audio 
    block will be provided as the TextMsg list at the beginning of the next audio block.
    The list is cleared after the first sample of the audio block.

    For example usage, see the [TODO] file in 'Examples.'
    """

    var strings: List[String]
    var received_message: Bool

    fn __init__(out self, default: List[String] = List[String]()):
        """Initialize the TextMsg, with an optional default. 
        
        If a default 
        list of strings is provided, this will be in the TextMsg for the first 
        sample of the first audio block and then will be cleared. This might 
        be useful for loading something
        at the very start of the program run.
        """
        self.strings = default.copy()
        self.received_message = False

    @doc_private
    fn __repr__(self) -> String:
        s = String("[")
        for i in range(self.strings.__len__()):
            s += String(self.strings[i])
            if i < self.strings.__len__() - 1:
                s += String(", ")
        s += String("]")
        return s

    fn __as_list__(self) -> List[String]:
        return self.strings.copy()
    
    fn __iter__(self) -> _TextMsgIter:
        """Return an iterator over the strings in this TextMsg."""
        return _TextMsgIter(UnsafePointer(to=self.strings))

    @doc_private
    fn write_to(self, mut writer: Some[Writer]):
        writer.write("[ ")
        for v in self.strings:
            writer.write(v + " ")
        writer.write("]")

    fn __len__(self) -> Int:
        """Return the number of strings in this TextMsg. This dunder can be used as:
        
        # ```mojo
        # txt = TextMsg(["hello", "world"])
        # len(txt) # returns 2
        # ```
        
        """
        return len(self.strings)

    fn __getitem__(self, index: Int) -> String:
        """Get the string at the specified index. This dunder can be used as:
        
        ```mojo
        txt = TextMsg(["hello", "world"])
        first = txt[0] # first is "hello"
        ```
        
        """
        return self.strings[index]
    
    fn __bool__(self) -> Bool:
        """A TextMsg is considered 'True' if it has at least one string in it.
        
        This is useful for checking if any text messages have arrived. See `__as_bool__` for more details.
        """
        return len(self.strings) > 0

    fn __as_bool__(self) -> Bool:
        """A TextMsg is considered 'True' if it has at least one string in it.
        
        > Note that you'll still need to index into the List inside the TextMsg 
        to get the actual strings! If it's possible that there are multiple strings,
        best practices would be:

        ```mojo
        self.txt = TextMsg()
        # ...
        if self.txt:
            for t in self.txt:
                do_something(t)
        ```
        """
        return len(self.strings) > 0

@doc_private
struct _TextMsgIter:
    """Iterator for TextMsg."""
    var strings: UnsafePointer[List[String]]
    var index: Int

    fn __init__(out self, strings: UnsafePointer[List[String]]):
        self.strings = strings
        self.index = 0

    fn __next__(mut self) -> String:
        var result = self.strings[][self.index]
        self.index += 1
        return result

    fn __has_next__(self) -> Bool:
        return self.index < len(self.strings[])

    fn __len__(self) -> Int:
        return len(self.strings[]) - self.index
