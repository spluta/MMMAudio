from mmm_src.MMMWorld import *
from utils import Variant

struct GateMsg(Movable, Copyable, Representable, Boolable, Writable):
    var name: String
    var state: Bool

    fn __init__(out self, name: String, default: Bool):
        self.name = name
        self.state = default

    fn __as_bool__(self) -> Bool:
        return self.state

    fn __bool__(self) -> Bool:
        return self.state

    fn __repr__(self) -> String:
        return String(self.state)
    
    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.state)

struct ListFloat64Msg(Movable, Copyable, Representable, Writable, Sized):
    var name: String
    var values: List[Float64]

    fn __init__(out self, name: String, default: List[Float64]):
        self.name = name
        self.values = default.copy()

    fn __repr__(self) -> String:
        s = String("[")
        for i in range(self.values.__len__()):
            s += String(self.values[i])
            if i < self.values.__len__() - 1:
                s += String(", ")
        s += String("]")
        return s
        
    fn __getitem__(self, index: Int64) -> Float64:
        return self.values[index]
    
    fn __setitem__(mut self, index: Int64, value: Float64):
        self.values[index] = value

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("[ ")
        for v in self.values:
            writer.write(String(v) + " ")
        writer.write("]")

    fn __len__(self) -> Int:
        return self.values.__len__()

struct TrigMsg(Movable, Copyable, Representable, Writable, Boolable):
    var name: String
    var state: Bool

    fn __init__(out self, name: String, default: Bool):
        self.name = name
        self.state = default

    fn __as_bool__(self) -> Bool:
        return self.state

    fn __bool__(self) -> Bool:
        return self.state

    fn __repr__(self) -> String:
        return String(self.state)

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.state)

struct TextMsg(Movable, Copyable, Representable, Writable, Sized):
    var name: String
    var strings: List[String]

    fn __init__(out self, name: String, default: List[String]):
        self.name = name
        self.strings = default.copy()

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

    fn write_to(self, mut writer: Some[Writer]):
        writer.write("[ ")
        for v in self.strings:
            writer.write(v + " ")
        writer.write("]")

    fn __len__(self) -> Int:
        return len(self.strings)

struct Messenger():
    # [TODO] Messenger needs a Set to keep track of all the keys
    # so that there can't be a key collision even if one is for
    # a different type of message.

    # [TODO] Add Optional namespace with default = None

    var world_ptr: UnsafePointer[MMMWorld]
    var gate_dict: Dict[String, UnsafePointer[GateMsg]]
    var trig_dict: Dict[String, UnsafePointer[TrigMsg]]
    var list_dict: Dict[String, UnsafePointer[ListFloat64Msg]]
    var text_dict: Dict[String, UnsafePointer[TextMsg]]

    var float64_dict: Dict[String, UnsafePointer[Float64]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.gate_dict = Dict[String, UnsafePointer[GateMsg]]()
        self.trig_dict = Dict[String, UnsafePointer[TrigMsg]]()
        self.list_dict = Dict[String, UnsafePointer[ListFloat64Msg]]()
        self.text_dict = Dict[String, UnsafePointer[TextMsg]]()

        self.float64_dict = Dict[String, UnsafePointer[Float64]]()

    fn add_param(mut self, ref param: Float64, name: String) -> None:
        self.float64_dict[name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: GateMsg) -> None:
        self.gate_dict[param.name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: TrigMsg) -> None:
        self.trig_dict[param.name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: ListFloat64Msg) -> None:
        self.list_dict[param.name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: TextMsg) -> None:
        self.text_dict[param.name] = UnsafePointer(to=param)

    fn update(self) -> None:
        if self.world_ptr[].block_state == 0:
            try: 
                # This all goes in a try block because all of the get_* functions are
                # marked "raises." They need to because that is required in order to 
                # access non-copies of the values in the message Dicts.
                
                for ref item in self.gate_dict.items():
                    var opt: Optional[Bool] = self.world_ptr[].messengerManager.get_gate(item.key)
                    if opt:
                        item.value[].state = opt.value()

                for ref item in self.trig_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_trig(item.key)
                    if opt:
                        item.value[].state = opt
                
                for ref item in self.list_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_list(item.key)
                    if opt:
                        item.value[].values = opt.value().copy()
                
                for ref item in self.text_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_text(item.key)
                    if opt:
                        item.value[].strings = opt.value().copy()
                
                for ref item in self.float64_dict.items():
                    var opt = self.world_ptr[].messengerManager.get_float(item.key)
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