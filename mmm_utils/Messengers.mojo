from mmm_src.MMMWorld import MMMWorld


struct Messenger[is_trigger: Bool = False](Floatable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var value: Float64
    var int_value: Int64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], default: Float64 = 0.0):
        self.world_ptr = world_ptr
        self.value = default
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
            self.value = opt.value()[0]
            self.int_value = Int64(self.value)
    
    fn set_value(mut self, val: Float64):
        self.value = val
        self.int_value = Int64(val)

    fn __float__(self) -> Float64:
        return self.value

struct TextMessenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld] 
    var value: String
    var changed: Bool = false

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], default: String = ""):
        self.world_ptr = world_ptr
        self.value = default

    @always_inline
    fn get_text_msg(mut self: Self, str: String):
        opt = self.world_ptr[0].get_text_msg(str)
        if opt: 
            self.value = String(opt.value()[0])
            self.changed = true
        else:
            self.changed = false
    
    fn set_value(mut self, val: String):
        self.value = val


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