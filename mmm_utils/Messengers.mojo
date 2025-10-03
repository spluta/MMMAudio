from mmm_src.MMMWorld import MMMWorld

struct Messenger(Floatable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var value: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], default: Float64 = 0.0):
        self.world_ptr = world_ptr
        self.value = default

    fn get_msg(mut self: Self, str: String):
        opt = self.world_ptr[0].get_msg(str) # trig will be an Optional
        if opt: # if it trig is None, we do nothing
            self.value = opt.value()[0]

    fn __float__(self) -> Float64:
        return self.value

struct MIDIMessenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance
    var value: List[List[Int64]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.value = List[List[Int64]]()

    fn get_note_ons(mut self: Self, channel: Int64 = -1, note: Int64 = -1):
        if self.world_ptr[0].grab_messages == 1:
            if channel != -1 or note != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].note_ons:
                    if (channel == -1 or item[0] == channel) and (note == -1 or item[1] == note):
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].note_ons.copy()
        else:
            self.value.clear()

    fn get_note_offs(mut self: Self, channel: Int64 = -1, note: Int64 = -1):
        if self.world_ptr[0].grab_messages == 1:
            self.value.clear()
            if channel != -1 or note != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].note_offs:
                    if (channel == -1 or item[0] == channel) and (note == -1 or item[1] == note):
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].note_offs.copy()

    fn get_ccs(mut self: Self, channel: Int64 = -1, cc: Int64 = -1):
        if self.world_ptr[0].grab_messages == 1:
            self.value.clear()
            if channel != -1 or cc != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].ccs:
                    if (channel == -1 or item[0] == channel) and (cc == -1 or item[1] == cc):
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].ccs.copy()
            

    fn get_bends(mut self: Self, channel: Int64 = -1):
        if self.world_ptr[0].grab_messages == 1:
            self.value.clear()
            if channel != -1:
                filtered = List[List[Int64]]()
                for item in self.world_ptr[0].bends:
                    if item[0] == channel:
                        filtered.append(item.copy())
                self.value = filtered^
            else:
                self.value = self.world_ptr[0].bends.copy()