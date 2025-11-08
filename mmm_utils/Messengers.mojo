from mmm_src.MMMWorld import *

struct Messenger(Copyable, Movable):
    """Messenger is a struct to enable communication between Python and Mojo."""

    var namespace: Optional[String]
    var world_ptr: UnsafePointer[MMMWorld]

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
        self.key_dict = Dict[String, String]()

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

    fn check_floats(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                temp = self.world_ptr[].messengerManager.check_floats(self.get_long_name(name)[])
                return temp
            except error:
                print("Error occurred while checking float message. Error: ", error)
        return False

    fn update(mut self, mut param: Bool, name: String) -> None:
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_gate(self.get_long_name(name)[])
                if opt:
                    param = opt.value()    
            except error:
                print("Error occurred while updating bool message. Error: ", error)

    fn update(mut self, mut param: Trig, name: String) -> None:
        if self.world_ptr[].top_of_block or self.world_ptr[].block_state == 1:
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

struct Trig(Representable, Writable, Boolable, Copyable, Movable):
    """A 'Trigger' that can be controlled from Python.

    It is either True (triggered) or False (not triggered). 
    It works like a boolean in all places, but different from a boolean it can be
    registered with a Messenger under a user specified name. 
    
    It only make sense to use TrigMsg if it is registered with a Messenger. Otherwise 
    you can just use a Bool directly.
    
    The Messenger checks for any
    'triggers' sent under the specified name at the start of each audio block, and sets
    the TrigMsg's state accordingly. If there is a trigger under the name, this TrigMsg
    will be True for 1 sample (the first of the audio block), and then automatically reset to
    False for the rest of the block.

    For an usage example, see the [TODO] file in 'Examples.'
    """
    var state: Bool

    fn __init__(out self, starting_state: Bool = False):
        """Initialize the TrigMsg with an optional starting state. 
        
        If the starting
        state is set to True, this TrigMsg will be true for the first sample of the
        first audio block and then go down to False on the very next sample. This might be
        useful for initializing some process at the beginning of the audio thread, but note
        that many processes look for a *change* from low to high, so if this TrigMsg starts 
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
