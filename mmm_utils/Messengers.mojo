from mmm_src.MMMWorld import *
from utils import Variant

struct GateMsg(Representable, Boolable, Writable):
    var state: Bool

    fn __init__(out self, default: Bool = False):
        self.state = default
        self.state = default

    fn __as_bool__(self) -> Bool:
        return self.state

    fn __bool__(self) -> Bool:
        return self.state

    fn __repr__(self) -> String:
        return String(self.state)
    
    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.state)

struct TrigMsg(Representable, Writable, Boolable):
    var state: Bool

    fn __init__(out self, default: Bool = False):
        self.state = default

    fn __as_bool__(self) -> Bool:
        return self.state

    fn __bool__(self) -> Bool:
        return self.state

    fn __repr__(self) -> String:
        return String(self.state)

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.state)

struct TextMsg(Representable, Writable, Sized):
    var strings: List[String]

    fn __init__(out self, default: List[String] = List[String]()):
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
    # [TODO] Add Optional namespace with default = None
    var world_ptr: UnsafePointer[MMMWorld]
    var all_keys: Set[String]
    var gate_dict: Dict[String, UnsafePointer[GateMsg]]
    var trig_dict: Dict[String, UnsafePointer[TrigMsg]]
    var list_dict: Dict[String, UnsafePointer[List[Float64]]]
    var text_dict: Dict[String, UnsafePointer[TextMsg]]
    var float64_dict: Dict[String, UnsafePointer[Float64]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.gate_dict = Dict[String, UnsafePointer[GateMsg]]()
        self.trig_dict = Dict[String, UnsafePointer[TrigMsg]]()
        self.list_dict = Dict[String, UnsafePointer[List[Float64]]]()
        self.text_dict = Dict[String, UnsafePointer[TextMsg]]()
        self.float64_dict = Dict[String, UnsafePointer[Float64]]()
        self.all_keys = Set[String]()

    fn check_key_collision(mut self, name: String) -> None:
        try:
            if name in self.all_keys:
                raise Error("Messenger key collision: The key '" + name + "' is already in use.")
            self.all_keys.add(name)
        except error:
            print("Error occurred while checking key collision. Error: ", error)

    fn add_param(mut self, ref param: Float64, name: String) -> None:
        self.check_key_collision(name)
        self.float64_dict[name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: GateMsg, name: String) -> None:
        self.check_key_collision(name)
        self.gate_dict[name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: TrigMsg, name: String) -> None:
        self.check_key_collision(name)
        self.trig_dict[name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: List[Float64], name: String) -> None:
        self.check_key_collision(name)
        self.list_dict[name] = UnsafePointer(to=param)

    fn add_param(mut self, ref param: TextMsg, name: String) -> None:
        self.check_key_collision(name)
        self.text_dict[name] = UnsafePointer(to=param)

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
                        item.value[] = opt.value().copy()
                
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