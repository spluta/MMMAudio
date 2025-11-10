from mmm_src.MMMWorld import *

struct Messenger(Copyable, Movable):
    """Messenger is a struct to enable communication between Python and Mojo."""

    var namespace: Optional[String]
    var world_ptr: UnsafePointer[MMMWorld]

    var key_dict: Dict[String, String]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], namespace: Optional[String] = None):
        """Initialize the Messenger.

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
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_bool(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating bool message. Error: ", error)
    
    # has_new Bool
    fn has_new_bool(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.bool_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new bool message. Error: ", error)
        return False

    # update List[Bool]
    fn update(mut self, mut param: List[Bool], name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_bools(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
            except error:
                print("Error occurred while updating bool message. Error: ", error)

    # has_new List[Bool]
    fn has_new_bools(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.bools_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new bool list message. Error: ", error)
        return False

    # update Float64
    fn update(mut self, mut param: Float64, name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_float(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating float message. Error: ", error)

    # has_new Float64
    fn has_new_float(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.float_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new float message. Error: ", error)
        return False

    # update List[Float64]
    fn update(mut self, mut param: List[Float64], ref name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_floats(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
            except error:
                print("Error occurred while updating float list message. Error: ", error)

    # has_new List[Float64]
    fn has_new_floats(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.floats_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new float list message. Error: ", error)
        return False

    # update Int64
    fn update(mut self, mut param: Int64, name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_int(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating int message. Error: ", error)

    # has_new Int64
    fn has_new_int(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.int_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new int message. Error: ", error)
        return False

    # update List[Int64]
    fn update(mut self, mut param: List[Int64], ref name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_ints(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
            except error:
                print("Error occurred while updating int list message. Error: ", error)

    # has_new List[Int64]
    fn has_new_ints(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.ints_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new int list message. Error: ", error)
        return False

    # update String
    fn update(mut self, mut param: String, name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_string(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value()
            except error:
                print("Error occurred while updating text message. Error: ", error)

    # has_new String
    fn has_new_string(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.string_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new string message. Error: ", error)
        return False

    # update List[String]
    fn update(mut self, mut param: List[String], name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_strings(self.get_name_with_namespace(name)[])
                if opt:
                    param = opt.value().copy()
            except error:
                print("Error occurred while updating text message. Error: ", error)

    # has_new List[String]
    fn has_new_strings(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.strings_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new string list message. Error: ", error)
        return False

    # update Trig
    fn update(mut self, mut param: Trig, name: String):
        if self.world_ptr[].top_of_block or self.world_ptr[].block_state == 1:
            try:
                param.state = self.world_ptr[].messengerManager.get_trig(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while updating trig message. Error: ", error)

    # has_new Trig
    fn has_new_trig(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.trig_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new trig message. Error: ", error)
        return False

    # update List[Trig]
    fn update(mut self, mut param: List[Trig], name: String):
        if self.world_ptr[].top_of_block:
            try:
                var opt = self.world_ptr[].messengerManager.get_trigs(self.get_name_with_namespace(name)[])
                if opt:
                    param = [Trig(v) for v in opt.value()]
            except error:
                print("Error occurred while updating trig message. Error: ", error)
        elif self.world_ptr[].block_state == 1:
            for ref t in param:
                t.state = False

    # has_new List[Trig]
    fn has_new_trigs(mut self, name: String) -> Bool:
        if self.world_ptr[].top_of_block:
            try:
                return self.world_ptr[].messengerManager.trigs_msgs.__contains__(self.get_name_with_namespace(name)[])
            except error:
                print("Error occurred while checking for new trig list message. Error: ", error)
        return False

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