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

    fn __init__(out self, value: List[Float64]):
        self.retrieved = False
        self.value = value.copy()

struct Float64Message(Movable, Copyable):
    var retrieved: Bool
    var value: Float64

    fn __init__(out self, value: Float64):
        self.retrieved = False
        self.value = value

struct GateMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Bool

    fn __init__(out self, value: Bool):
        self.retrieved = False
        self.value = value

struct TextMessage(Movable, Copyable):
    var values: List[String]
    var retrieved: Bool

    fn __init__(out self, values: List[String]):
        self.values = values.copy()
        self.retrieved = False

struct MessengerManager(Movable, Copyable):

    var list_msg_pool: Dict[String, List[Float64]]
    var list_msgs: Dict[String, ListMessage]
    
    var float_msg_pool: Dict[String, Float64]
    var float_msgs: Dict[String, Float64Message]
    
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
        self.float_msgs = Dict[String, Float64Message]()

        self.gate_msg_pool = Dict[String, Bool]()
        self.gate_msgs = Dict[String, GateMessage]()

        self.trig_msg_pool = Set[String]()
        self.trig_msgs = Dict[String, Bool]()
        
        self.text_msg_pool = Dict[String, List[String]]()
        self.text_msgs = Dict[String, TextMessage]()

    # update_* functions add messages to the pool to be transferred at the
    # start of the next audio block. These functions are called from MMMAudioBridge
    # when a message is sent from Python.
    @always_inline
    fn update_float_msg(mut self, key: String, value: Float64):
        self.float_msg_pool[key] = value

    @always_inline
    fn update_gate_msg(mut self, key: String, value: Bool):
        self.gate_msg_pool[key] = value

    @always_inline
    fn update_list_msg(mut self, key: String, values: List[Float64]):
        self.list_msg_pool[key] = values.copy()

    @always_inline
    fn update_trig_msg(mut self, key: String):
        self.trig_msg_pool.add(key)

    @always_inline
    fn update_text_msg(mut self, key: String, text: String) raises:
        if not key in self.text_msg_pool:
            self.text_msg_pool[key] = List[String]()
        self.text_msg_pool[key].append(text)

    fn transfer_msgs(mut self) raises:

        for list_msg in self.list_msg_pool.take_items():
            self.list_msgs[list_msg.key] = ListMessage(list_msg.value)

        for float_msg in self.float_msg_pool.take_items():
            self.float_msgs[float_msg.key] = Float64Message(float_msg.value)


        for gate_msg in self.gate_msg_pool.take_items():
            self.gate_msgs[gate_msg.key] = GateMessage(gate_msg.value)

        for text_msg in self.text_msg_pool.take_items():
            self.text_msgs[text_msg.key] = TextMessage(text_msg.value.copy())

        for trig_msg_str in self.trig_msg_pool:
            self.trig_msgs[trig_msg_str] = False  # Set retrieved Bool to False initially
        # The other pools are Dicts so "take_items()" empties them, but since
        # trig_msg_pool is a Set, we have to clear it manually:
        self.trig_msg_pool.clear() 

    # get_* functions retrieve messages from the Dicts *after* they have
    # been transferred from the pools to the Dicts. These functions are called
    # from a graph (likely via a Messenger instance) to get the latest message values.
    @always_inline
    fn get_float(mut self, key: String) raises -> Optional[Float64]:
        if key in self.float_msgs:
            self.float_msgs[key].retrieved = True
            return self.float_msgs[key].value
        return None

    @always_inline
    fn get_gate(mut self, key: String) raises -> Optional[Bool]:
        if key in self.gate_msgs:
            self.gate_msgs[key].retrieved = True
            return self.gate_msgs[key].value
        return None

    @always_inline
    fn get_list(mut self: Self, key: String) raises-> Optional[List[Float64]]:
        if key in self.list_msgs:
            self.list_msgs[key].retrieved = True
            # Copy is ok here because it will only copy when there is a
            # new list for it to use, which should be rare. If the user
            # is, like, streaming lists of tons of values, they should
            # be using a different method, such as loading the data into
            # a buffer ahead of time and reading from that.
            return self.list_msgs[key].value.copy()
        return None

    @always_inline
    fn get_trig(mut self, key: String) -> Bool:
        if key in self.trig_msgs:
            self.trig_msgs[key] = True
            return True
        return False

    # Unlike the other "get_*" functions, this one returns an Optional List of Strings
    # because it doesn't make sense for there to be a default value for text messages.
    @always_inline
    fn get_text(mut self, key: String) raises -> Optional[List[String]]:
        if key in self.text_msgs:
            self.text_msgs[key].retrieved = True
            # Copy here is ok because text messages are expected
            # to be rare, so this shouldn't happen often.
            return self.text_msgs[key].values.copy()
        return None

    fn empty_msg_dicts(mut self):
        for list_msg in self.list_msgs.take_items():
            if not list_msg.value.retrieved:
                print("List message was not retrieved this block:", list_msg.key)

        for float_msg in self.float_msgs.take_items():
            if not float_msg.value.retrieved:
                print("Float message was not retrieved this block:", float_msg.key)

        for gate_msg in self.gate_msgs.take_items():
            if not gate_msg.value.retrieved:
                print("Gate message was not retrieved this block:", gate_msg.key)
        
        for trig_msg in self.trig_msgs.take_items():
            if not trig_msg.value: # It wasn't retrieved this block
                print("Trig message", trig_msg.key, "was not retrieved this block.")

        for text_msg in self.text_msgs.take_items():
            if not text_msg.value.retrieved:
                print("Text message", text_msg.key, "was not retrieved this block.")
                for val in text_msg.value.values:
                    print("   Value:", val)

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
    
    @always_inline
    fn print[N: Int](mut self, value: List[SIMD[DType.float64, N]], label: String = "", freq: Float64 = 10.0, end_str: String = " ") -> None:

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
                out_str = label
                for i in range(len(value)):
                    out_str = out_str + String(value[i]) + end_str
                print(out_str)


