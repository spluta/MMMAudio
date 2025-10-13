from mmm_src.MMMWorld import *



struct Messenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var msg_dict: Dict[String, UnsafePointer[MiniMessenger]]
    var default_dict: Dict[String, Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.msg_dict = Dict[String, UnsafePointer[MiniMessenger]]()
        self.default_dict = Dict[String, Float64]()

    fn get_val(mut self, key: String, default: Float64) -> Float64:
        ptr = self.world_ptr[0].get_messenger(key)
        if ptr:
            ptr.value()[0].grabbed = True
            return ptr.value()[0].lists[0][0]
        else:
            return default

    # fn __float__(mut self, key: String, default: Float64) -> Float64:
    #     return self.get_val(key, default)
    
    # fn __int__(mut self, key: String, default: Float64) -> Int64:
    #     return Int64(self.get_val(key, default))

    fn triggered(mut self, key: String) -> Bool:
    
    # Return the trigger state (val if triggered, 0.0 otherwise) of the messenger with the given key.

        ptr = self.world_ptr[0].get_messenger(key)
        if ptr:
            if ptr.value()[0].triggered:
                ptr.value()[0].grabbed = True
                return True
        return False

    fn get_list(mut self, key: String) -> List[Float64]:
        ptr = self.world_ptr[0].get_messenger(key)

        if ptr:
            if ptr.value()[0].triggered:
                ptr.value()[0].grabbed = True
                return ptr.value()[0].lists[0].copy()
            else:
                return List[Float64]().copy()
        else:
            return List[Float64]().copy()

    # fn get_list(mut self, key: String) -> (List[Float64], Bool):
        
    #     ptr = self.world_ptr[0].get_messenger(key)

    #     if ptr:
    #         if ptr.value()[0].triggered:
    #             ptr.value()[0].grabbed = True
    #             return (ptr.value()[0].lists[0].copy(), True)
    #         else:
    #             return (List[Float64]().copy(), False)
    #     else:
    #         return (List[Float64]().copy(), False)

    fn get_lists(mut self, key: String) -> List[List[Float64]]:
        """
        This version of get_lists will return all messages for the given key
        """
        
        ptr = self.world_ptr[0].get_messenger(key)

        if ptr:
            if ptr.value()[0].triggered:
                ptr.value()[0].grabbed = True
                return ptr.value()[0].lists.copy()
            else:
                return List[List[Float64]]().copy()
        else:
            return List[List[Float64]]().copy()

    fn get_lists(mut self, key: String, *filters: Optional[Int]) -> List[List[Float64]]:
        """
        This version of get_lists filters out messages based on the filters provided
        If a filter is None, that position is ignored
        If a filter is an Int, only messages with that value in that position are included
        e.g. get_lists("note_on", None, 48) will return only note_on messages with a value of 48 in the second position (the note number)
        """
        ptr = self.world_ptr[0].get_messenger(key)

        if ptr:
            if ptr.value()[0].triggered:
                ptr.value()[0].grabbed = True
                if len(filters) == 0:
                    return ptr.value()[0].lists.copy()
                elif len(filters) > 0:
                    big_list = List[List[Float64]]().copy()
                    for item in ptr.value()[0].lists:
                        include = [False for _ in range(len(filters))]
                        for i in range(min(len(filters), len(item))):
                            if filters[i]==None or item[i] == filters[i].value():
                                include[i] = True

                        if all(include):
                            big_list.append(item.copy())
                    return big_list.copy()
        return List[List[Float64]]().copy()

struct TextMessenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var triggered: Bool

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.triggered = False

    @always_inline
    fn get_text_msg_val(mut self: Self, key: String) -> String:
        """
        Retrieves a text message associated with the given key from the world's text message dictionary.

        Args:
            key: String - The key to look for in the text message dictionary.

        Returns:
            A tuple containing the message (String) and a boolean indicating if it was triggered (Bool).
            
            Returns a tuple (message, triggered)
            
            If no message is found, returns ("", False).

        """
        opt = self.world_ptr[0].get_text_msgs(key)
        if opt: 
            self.triggered = True
            return opt.value()[0]
        else:
            self.triggered = False
            return ""

    @always_inline
    fn get_text_msg_list(mut self: Self, key: String) -> List[String]:
        """
        Retrieves a text message associated with the given key from the world's text message dictionary.

        Args:
            key: String - The key to look for in the text message dictionary.

        Returns:
            A tuple containing the message (String) and a boolean indicating if it was triggered (Bool).
            
            Returns a tuple (message, triggered)
            
            If no message is found, returns ("", False).

        """
        opt = self.world_ptr[0].get_text_msgs(key)
        if opt:
            self.triggered = True
            return opt.value().copy()
        else:
            self.triggered = False
            return List[String]()

# struct MessengerManager(Movable, Copyable):
#     var world_ptr: UnsafePointer[MMMWorld]  
#     var messengers: Dict[String, Messenger]
#     # var text_messengers: Dict[String, TextMessenger]

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         self.world_ptr = world_ptr
#         self.messengers = Dict[String, Messenger]()
#         # self.text_messengers = Dict[String, TextMessenger]()

#     fn add_messenger[is_trigger: Bool = False](mut self, key: String, default: Float64 = 0.0):
#         messenger = Messenger(self.world_ptr, key, default)
#         self.messengers[key] = messenger.copy()

#     # fn add_text_messenger(mut self, key: String, default: String = ""):
#     #     messenger = TextMessenger(self.world_ptr, default)
#     #     self.text_messengers[key] = messenger.copy()

#     fn get_messages(mut self):
#         if self.world_ptr[0].top_of_block:
#             for ref item in self.messengers.items():
#                 item.value.get_msg()  # Update each messenger
#             # for value in self.text_messengers.lists():
#             #     value.get_text_msg()  # Update each text messenger
#         if self.world_ptr[0].block_state == 1:
#             for ref item in self.messengers.items():
#                 item.value.trig = False
#             # for value in self.text_messengers.lists():
#             #     value.trig = False

#     fn lists(self, key: String) -> List[List[Float64]]:
#         if key not in self.messengers:
#             return List[List[Float64]]()
#         else:
#             opt = self.messengers.get(key)
#             if opt:
#                 return opt.value().lists.copy()
#             else:
#                 return List[List[Float64]]()

#     fn list(self, key: String) -> List[Float64]:
#         if key not in self.messengers:
#             return List[Float64]()
#         else:
#             opt = self.messengers.get(key)
#             if opt:
#                 return opt.value().lists[0].copy()
#             else:
#                 return List[Float64]()

#     fn value(self, key: String) -> Float64:
#         if key not in self.messengers:
#             return 0.0
#         else:
#             opt = self.messengers.get(key)
#             if opt:
#                 return opt.value().lists[0][0]
#             else:
#                 return 0.0

#     fn trig(self, key: String) -> Int:
#         if key not in self.messengers:
#             return 0
#         else:
#             opt = self.messengers.get(key)
#             if opt:
#                 return opt.value().trig()
#             else:
#                 return 0

# struct Messenger(Movable, Copyable):
#     var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
#     var get_lists: List[List[Float64]]
#     var get_list: List[Float64]
#     var val: Float64
#     var trigger: Bool

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], *default: Float64):
#         self.world_ptr = world_ptr
#         self.get_lists = List[List[Float64]]()

#         if len(default) == 0:
#             temp = [0.0]  # Default to a single zero if no default is provided
#         else:
#             temp = [x for x in default]  # Expand the default values
#         self.get_lists.append(temp.copy())
#         self.get_list = self.get_lists[0].copy()
#         self.val = self.get_lists[0][0]
#         self.trigger = False

#     @always_inline
#     fn get_msg(mut self: Self, key: String):
#         ref opt = self.world_ptr[0].get_msg(key)
#         if opt: 
#             self.get_lists.clear()
#             for val in opt.value():
#                 self.get_lists.append(val.copy())
#             self.get_list = self.get_lists[0].copy()
#             self.val = self.get_lists[0][0]
#             self.trigger = True
#         else:
#             self.trigger = False
    
#     fn set_value(mut self, val: List[List[Float64]]):
#         self.get_lists = val.copy()
#         self.get_list = val[0].copy()
#         self.val = val[0][0]
#         self.trigger = True
    
#     fn set_value(mut self, val: Float64):
#         self.get_list = [val]
#         self.val = val
#         self.get_lists.clear()
#         self.get_lists.append([val])
#         self.trigger = True
