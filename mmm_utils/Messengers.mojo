from mmm_src.MMMWorld import *
from utils import Variant

struct Float64Param(Movable, Copyable, Representable, Floatable, Writable):
    var name: String
    var value: Float64

    fn __init__(out self, name: String, default: Float64):
        self.name = name
        self.value = default

    fn __as_float__(self) -> Float64:
        return self.value

    fn __float__(self) -> Float64:
        return self.value

    fn __repr__(self) -> String:
        return String(self.value)

    fn write_to(self, mut writer: Some[Writer]):
        writer.write(self.value)

struct GateParam(Movable, Copyable, Representable, Boolable, Writable):
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

struct ListFloat64Param(Movable, Copyable, Representable, Writable, Sized):
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

struct TrigParam(Movable, Copyable, Representable, Writable, Boolable):
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

struct TextParam(Movable, Copyable, Representable, Writable, Sized):
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

struct Messenger(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var float_dict: Dict[String, UnsafePointer[Float64Param]]
    var gate_dict: Dict[String, UnsafePointer[GateParam]]
    var trig_dict: Dict[String, UnsafePointer[TrigParam]]
    var list_dict: Dict[String, UnsafePointer[ListFloat64Param]]
    var text_dict: Dict[String, UnsafePointer[TextParam]]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.float_dict = Dict[String, UnsafePointer[Float64Param]]()
        self.gate_dict = Dict[String, UnsafePointer[GateParam]]()
        self.trig_dict = Dict[String, UnsafePointer[TrigParam]]()
        self.list_dict = Dict[String, UnsafePointer[ListFloat64Param]]()
        self.text_dict = Dict[String, UnsafePointer[TextParam]]()

    # [TODO] I have to believe there is a way to use polymorphism to have 
    # just one add_param function instead of five...
    fn add_float64_param(mut self, ref param: Float64Param) -> None:
        self.float_dict[param.name] = UnsafePointer(to=param)

    fn add_gate_param(mut self, ref param: GateParam) -> None:
        self.gate_dict[param.name] = UnsafePointer(to=param)
    
    fn add_trig_param(mut self, ref param: TrigParam) -> None:
        self.trig_dict[param.name] = UnsafePointer(to=param)
    
    fn add_list_float64_param(mut self, ref param: ListFloat64Param) -> None:
        self.list_dict[param.name] = UnsafePointer(to=param)

    fn add_text_param(mut self, ref param: TextParam) -> None:
        self.text_dict[param.name] = UnsafePointer(to=param)

    fn update(self) -> None:
        if self.world_ptr[].block_state == 0:
            for item in self.float_dict.items():
                var opt = self.world_ptr[].messengerManager.get_float(item.key)
                if opt:
                    item.value[].value = opt.value()
            
            for item in self.gate_dict.items():
                var opt: Optional[Bool] = self.world_ptr[].messengerManager.get_gate(item.key)
                if opt:
                    item.value[].state = opt.value()
            
            for item in self.trig_dict.items():
                var opt = self.world_ptr[].messengerManager.get_trig(item.key)
                if opt:
                    item.value[].state = opt
            
            for item in self.list_dict.items():
                var opt = self.world_ptr[].messengerManager.get_list(item.key)
                if opt:
                    item.value[].values = opt.value().copy()
            
            for item in self.text_dict.items():
                var opt = self.world_ptr[].messengerManager.get_text(item.key)
                if opt:
                    item.value[].strings = opt.value().copy()
        elif self.world_ptr[].block_state == 1:
            for item in self.trig_dict.items():
                item.value[].state = False
            for item in self.text_dict.items():
                item.value[].strings.clear()