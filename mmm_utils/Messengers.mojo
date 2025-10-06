from mmm_src.MMMWorld import MMMWorld

# struct MessengerManager(Movable, Copyable):
#     var world_ptr: UnsafePointer[MMMWorld]  
#     var messengers: List[Messenger]
#     var trig_messengers: List[TrigMessenger]
#     var text_messengers: List[TextMessenger]
#     var midi_messengers: List[MIDIMessenger]

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
#         self.world_ptr = world_ptr
#         self.messengers = List[Messenger]()
#         self.trig_messengers = List[TrigMessenger]()
#         self.text_messengers = List[TextMessenger]()
#         self.midi_messengers = List[MIDIMessenger]()

#     fn add_messenger[is_trigger: Bool = False](mut self, key: String, default: Float64 = 0.0):
#         messenger = Messenger(self.world_ptr, default)
#         self.messengers.append(messenger.copy())
    
#     fn add_trig_messenger(mut self, key: String, default: Float64 = 0.0):
#         messenger = TrigMessenger(self.world_ptr, default)
#         self.trig_messengers.append(messenger.copy())

#     fn add_text_messenger(mut self, key: String, default: String = ""):
#         messenger = TextMessenger(self.world_ptr, default)
#         self.text_messengers.append(messenger.copy())
    
#     fn add_midi_messenger(mut self, type: String = "note_on", channel: Int64 = -1, note: Int64 = -1):
#         messenger = MIDIMessenger(self.world_ptr)
#         messenger.type = type
#         messenger.channel = channel
#         messenger.note = note
#         self.midi_messengers.append(messenger.copy())

# struct TrigMessenger(Floatable, Movable, Copyable):
#     var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
#     var values: List[Float64]
#     var value: Float64
#     var int_value: Int64
#     var changed: Bool

#     fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], default: Float64 = 0.0):
#         self.world_ptr = world_ptr
#         self.values = List[Float64]()
#         self.value = default
#         self.int_value = Int64(default)
#         self.changed = False
#         self.int_value = Int64(default)

#     fn get_msg(mut self: Self, str: String):
#         if self.world_ptr[0].block_state == 1:
#             self.value = 0.0
#             self.int_value = 0
#             return  
#         opt = self.world_ptr[0].get_msg(str) 
#         if opt: 
#             self.values.clear()
#             for val in opt.value():
#                 self.values.append(val)
#             self.value = self.values[0]
#             self.int_value = Int64(self.value)
#             self.changed = True
#         else:
#             self.changed = False
    
#     fn set_value(mut self, val: Float64):
#         self.value = val
#         self.int_value = Int64(val)

#     fn __float__(self) -> Float64:
#         return self.value

#     fn __as_float__(self) -> Float64:
#         return self.value

struct Messenger[is_trigger: Bool = False](Floatable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var values: List[Float64]
    var value: Float64
    var int_value: Int64
    var changed: Bool

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], default: Float64 = 0.0):
        self.world_ptr = world_ptr
        self.values = List[Float64]()
        self.value = default
        self.int_value = Int64(default)
        self.changed = False
        self.int_value = Int64(default)

    fn get_msg(mut self: Self, str: String):
        # if the trigger parameter is set to true, we reset the value to 0.0 on the second sample of the audio block
        @parameter
        if is_trigger:
            if self.world_ptr[0].block_state == 1:
                self.value = 0.0
                self.int_value = 0
                return  
        opt = self.world_ptr[0].get_msg(str) 
        if opt: 
            self.values.clear()
            for val in opt.value():
                self.values.append(val)
            self.value = self.values[0]
            self.int_value = Int64(self.value)
            self.changed = True
        else:
            self.changed = False
    
    fn set_value(mut self, val: Float64):
        self.value = val
        self.int_value = Int64(val)

    fn __float__(self) -> Float64:
        return self.value

    fn __as_float__(self) -> Float64:
        return self.value

struct TextMessenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var changed: Bool
    var string: String

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], default: String = ""):
        self.world_ptr = world_ptr
        self.changed = False
        self.string = default

    @always_inline
    fn get_text_msg(mut self: Self, str: String):
        opt = self.world_ptr[0].get_text_msg(str)
        if opt: 
            self.changed = True
            self.string = opt.value()[0]
        else:
            self.changed = False
    
    fn set_value(mut self, val: String):
        self.string = val


struct MIDIMessenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var value: List[List[Int64]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.value = List[List[Int64]]()

    @always_inline
    fn get_note_ons(mut self: Self, channel: Int64 = -1, note: Int64 = -1):
        if self.world_ptr[0].block_state == 0:
            if channel != -1 or note != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].note_ons:
                    if (channel == -1 or item[0] == channel) and (note == -1 or item[1] == note):
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].note_ons.copy()
        elif self.world_ptr[0].block_state == 1:
            self.value.clear()

    @always_inline
    fn get_note_offs(mut self: Self, channel: Int64 = -1, note: Int64 = -1):
        if self.world_ptr[0].block_state == 0:
            self.value.clear()
            if channel != -1 or note != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].note_offs:
                    if (channel == -1 or item[0] == channel) and (note == -1 or item[1] == note):
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].note_offs.copy()
        elif self.world_ptr[0].block_state == 1:
            self.value.clear()

    @always_inline
    fn get_ccs(mut self: Self, channel: Int64 = -1, cc: Int64 = -1):
        if self.world_ptr[0].block_state == 0:
            self.value.clear()
            if channel != -1 or cc != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].ccs:
                    if (channel == -1 or item[0] == channel) and (cc == -1 or item[1] == cc):
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].ccs.copy()
        elif self.world_ptr[0].block_state == 1:
            self.value.clear()

    @always_inline
    fn get_bends(mut self: Self, channel: Int64 = -1):
        if self.world_ptr[0].block_state == 0:
            self.value.clear()
            if channel != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].bends:
                    if item[0] == channel:
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].bends.copy()