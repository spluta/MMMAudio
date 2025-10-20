from python import PythonObject
from mmm_dsp.OscBuffers import OscBuffers
from mmm_dsp.Buffer import Buffer
from mmm_utils.Windows import *
from mmm_utils.Print import Print
import time
from collections import Set

struct ListMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Float64]
    var is_new: Bool

    fn __init__(out self):
        self.retrieved = False
        self.value = []
        self.is_new = True

struct FloatMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Float64
    var is_new: Bool

    fn __init__(out self):
        self.retrieved = False
        self.value = 0.0
        self.is_new = True

struct GateMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Bool
    var is_new: Bool

    fn __init__(out self):
        self.retrieved = False
        self.value = False
        self.is_new = True

struct TextMessage(Movable, Copyable):
    var values: List[String]
    var retrieved: Bool

    fn __init__(out self, var values: List[String]):
        self.values = values^
        self.retrieved = False
        # TextMessage doesn't need an "is_new" 
        # flag because the Dict of TextMessages is
        # cleared every block

struct MessengerManager(Movable, Copyable):

    var list_msg_pool: Dict[String, List[Float64]]
    var list_msgs: Dict[String, ListMessage]
    
    var float_msg_pool: Dict[String, Float64]
    var float_msgs: Dict[String, FloatMessage]
    
    var gate_msg_pool: Dict[String, Bool]
    var gate_msgs: Dict[String, GateMessage]
    
    var trig_msg_pool: Set[String]
    # Rather than making a TrigMessage struct, we only need a Dict:
    # Keys are the "trig names" that have been pooled, the Bools are
    # whether or not they were retrieved this block.
    var trig_msgs: Dict[String, Bool]
    
    # Text Messages need a List of Strings because one could image sending
    # multiple pieces of information at once, for example multiple file paths
    # to load.
    var text_msg_pool: Dict[String, List[String]]
    var text_msgs: Dict[String, TextMessage]

    fn __init__(out self):

        self.list_msg_pool = Dict[String, List[Float64]]()
        self.list_msgs = Dict[String, ListMessage]()

        self.float_msg_pool = Dict[String, Float64]()
        self.float_msgs = Dict[String, FloatMessage]()

        self.gate_msg_pool = Dict[String, Bool]()
        self.gate_msgs = Dict[String, GateMessage]()

        self.trig_msg_pool = Set[String]()
        self.trig_msgs = Dict[String, Bool]()
        
        self.text_msg_pool = Dict[String, List[String]]()
        self.text_msgs = Dict[String, TextMessage]()

    @always_inline
    fn update_float_msg(mut self, key: String, value: Float64):
        self.float_msg_pool[key] = value

    @always_inline
    fn get_float(mut self, key: String, default: Float64 = 0.0) -> Float64:
        f = self.float_msgs.get(key)
        if f:
            f.value().retrieved = True
            return f.value().value
        return default

    fn update_gate_msg(mut self, key: String, value: Bool):
        self.gate_msg_pool[key] = value

    @always_inline
    fn get_gate(mut self, key: String, default: Bool = False) -> Bool:
        ref g = self.gate_msgs.get(key)
        if g:
            g.value().retrieved = True
            return g.value().value
        return default

    @always_inline
    fn update_list_msg(mut self, key: String, values: List[Float64]):
        self.list_msg_pool[key] = values.copy()

    # [TODO] implement get_list such that it returns a pointer to the list in
    # the list_msgs dict
    # @always_inline
    # fn get_list(mut self: Self, key: String) -> Pointer[List[Float64]]:
    #     l = self.list_msgs.get(key)
    #     if l:
    #         return Pointer[List[Float64]](l.value()^)
    #     return Pointer[List[Float64]](null)

    @always_inline
    fn update_trig_msg(mut self, key: String):
        self.trig_msg_pool.add(key)

    @always_inline
    fn get_trig(mut self, key: String) -> Bool:
        ref opt = self.trig_msgs.get(key)
        if opt:
            opt.value() = True
            return True
        return False

    @always_inline
    fn update_text_msg(mut self, key: String, text: String) raises:
        opt = self.text_msg_pool.get(key)
        if not opt:
            self.text_msg_pool[key] = List[String]()
        self.text_msg_pool[key].append(text)

    # Unlike the other "get_*" functions, this one returns an Optional List of Strings
    # because it doesn't make sense for there to be a default value for text messages.
    @always_inline
    fn get_text(mut self, key: String) -> Optional[List[String]]:
        ref opt = self.text_msgs.get(key)
        if opt:
            opt.value().retrieved = True
            return Optional[List[String]](opt.value().values.copy())
        return Optional[List[String]](None)

    fn transfer_msgs(mut self) raises:

        # Go through each item in the pool
        for list_msg in self.list_msg_pool.take_items():
            # See if it already exists in the Dict
            list_opt = self.list_msgs.get(list_msg.key)
            # If it doesn't, create a new value at that key
            if not list_opt:
                self.list_msgs[list_msg.key] = ListMessage()
            # Now there is definitely a key, so copy the value
            self.list_msgs[list_msg.key].value = list_msg.value.copy()
            # If it is in the pool it is new this block
            self.list_msgs[list_msg.key].is_new = True

        for float_msg in self.float_msg_pool.take_items():
            float_opt = self.float_msgs.get(float_msg.key)
            if not float_opt:
                self.float_msgs[float_msg.key] = FloatMessage()
            self.float_msgs[float_msg.key].value = float_msg.value
            # If it is in the pool it is new this block
            self.float_msgs[float_msg.key].is_new = True

        for gate_msg in self.gate_msg_pool.take_items():
            gate_opt = self.gate_msgs.get(gate_msg.key)
            if not gate_opt:
                self.gate_msgs[gate_msg.key] = GateMessage()
            self.gate_msgs[gate_msg.key].value = gate_msg.value
            # If it is in the pool it is new this block
            self.gate_msgs[gate_msg.key].is_new = True

        # Text Messages will be cleared after every computed audio block
        # so we know there won't be anything to check for (with Optionals like
        # above) in the Dicts, so we can just copy them over directly.
        for text_msg in self.text_msg_pool.take_items():
            self.text_msgs[text_msg.key] = TextMessage(text_msg.value)

        for trig_msg_str in self.trig_msg_pool:
            self.trig_msgs[trig_msg_str] = False  # Set retrieved Bool to False initially
        # The other pools are Dicts so "take_items()" empties them, but since
        # trig_msg_pool is a Set, we have to clear it manually:
        self.trig_msg_pool.clear() 

    fn un_new_msgs(mut self):
        for ref list_msg in self.list_msgs.items():
            if list_msg.value.is_new and not list_msg.value.retrieved:
                print("List message was not retrieved this block:", list_msg.key)
            list_msg.value.is_new = False

        for ref float_msg in self.float_msgs.items():
            # [TODO] Maybe "mouse_x" and "mouse_y" should be handled differently?
            if float_msg.key != "mouse_x" and float_msg.key != "mouse_y" and float_msg.value.is_new and not float_msg.value.retrieved:
                print("Float message was not retrieved this block:", float_msg.key)
            float_msg.value.is_new = False
        
        for ref gate_msg in self.gate_msgs.items():
            if gate_msg.value.is_new and not gate_msg.value.retrieved:
                print("Gate message was not retrieved this block:", gate_msg.key)
            gate_msg.value.is_new = False
        
        for ref trig_msg in self.trig_msgs.take_items():
            if not trig_msg.value: # It wasn't retrieved this block
                print("Trig message", trig_msg.key, "was not retrieved this block.")
        
        for ref text_msg in self.text_msgs.take_items():
            if not text_msg.value.retrieved:
                print("Text message", text_msg.key, "was not retrieved this block.")
                for val in text_msg.value.values:
                    print("   Value:", val)

    fn clear_trig_and_text_msgs(mut self):
        self.trig_msgs.clear()
        self.text_msgs.clear()

struct MMMWorld(Representable, Movable, Copyable):
    var sample_rate: Float64
    var block_size: Int64
    var osc_buffers: OscBuffers
    var num_in_chans: Int64
    var num_out_chans: Int64

    var sound_in: List[Float64]

    var screen_dims: List[Float64]  
     
    var os_multiplier: List[Float64]

    var mouse_x: Float64
    var mouse_y: Float64

    var block_state: Int64
    var top_of_block: Bool
    
    # windows
    var hann_window: Buffer

    var buffers: List[Buffer]

    var messengerManager: MessengerManager

    # var pointer_to_self: UnsafePointer[MMMWorld]
    var last_print_time: Float64
    var print_flag: Int64
    var last_print_flag: Int64

    fn __init__(out self, sample_rate: Float64 = 48000.0, block_size: Int64 = 64, num_in_chans: Int64 = 2, num_out_chans: Int64 = 2):
        self.sample_rate = sample_rate
        self.block_size = block_size
        self.top_of_block = False
        self.num_in_chans = num_in_chans
        self.num_out_chans = num_out_chans
        self.sound_in = List[Float64]()
        for _ in range(self.num_in_chans):
            self.sound_in.append(0.0)  # Initialize input buffer with zeros

        self.osc_buffers = OscBuffers()
        self.screen_dims = List[Float64](0.0, 0.0)  # Initialize screen dimensions with zeros
        self.hann_window = Buffer(List[List[Float64]](hann_window(2048)), self.sample_rate)  # Initialize Hann window

        self.os_multiplier = List[Float64]()  # Initialize the list of multipliers
        for i in range(5):  # Initialize multipliers for oversampling ratios
            self.os_multiplier.append(1.0 / (2 ** i))  # Example multipliers, can be adjusted as needed

        # I don't know why, but objects don't see these as updated? maybe it is copying the world when I pass it?
        self.mouse_x = 0.0
        self.mouse_y = 0.0

        self.block_state = 0

        self.buffers = List[Buffer]()  # Initialize the list of buffers
        self.last_print_time = 0.0
        self.print_flag = 0
        self.last_print_flag = 0

        self.messengerManager = MessengerManager()

        print("MMMWorld initialized with sample rate:", self.sample_rate, "and block size:", self.block_size)

    fn set_channel_count(mut self, num_in_chans: Int64, num_out_chans: Int64):
        self.num_in_chans = num_in_chans
        self.num_out_chans = num_out_chans
        self.sound_in = List[Float64]()
        for _ in range(self.num_in_chans):
            self.sound_in.append(0.0)  # Reinitialize input buffer with zeros

    fn __repr__(self) -> String:
        return "MMMWorld(sample_rate: " + String(self.sample_rate) + ", block_size: " + String(self.block_size) + ")"

    @always_inline
    fn print[T: Stringable](mut self, value: T, label: String = "", freq: Float64 = 10.0, end_str: String = " ") -> None:

        if self.block_state == 0:
            current_time = time.perf_counter()
            # this is really hacky, but we only want the print flag to be on for one sample at the top of the loop only if current time has exceed last print time
            if self.print_flag == 0:
                if current_time - self.last_print_time >= 1.0 / freq:
                    self.last_print_time = current_time
                    self.print_flag = 1
            elif self.print_flag == 1:
                self.print_flag = 0
            if self.print_flag == 1:
                print(label,String(value))


