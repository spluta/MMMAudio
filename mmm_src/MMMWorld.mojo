from python import PythonObject
from mmm_dsp.Buffer import OscBuffers
from mmm_dsp.Buffer import Buffer
from mmm_utils.Windows import *
from mmm_utils.Print import Print
import time
from collections import Set

struct FloatsMessage(Movable, Copyable):
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

struct GatesMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Bool]

    fn __init__(out self, value: List[Bool]):
        self.retrieved = False
        self.value = value.copy()

struct TrigsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Bool]

    fn __init__(out self, value: List[Bool]):
        self.retrieved = False
        self.value = value.copy()

struct TextMessage(Movable, Copyable):
    var values: List[String]
    var retrieved: Bool

    fn __init__(out self, values: List[String]):
        self.values = values.copy()
        self.retrieved = False

struct IntsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Int64]

    fn __init__(out self, value: List[Int64]):
        self.retrieved = False
        self.value = value.copy()

struct Int64Message(Movable, Copyable):
    var retrieved: Bool
    var value: Int64

    fn __init__(out self, value: Int64):
        self.retrieved = False
        self.value = value

struct MessengerManager(Movable, Copyable):

    var floats_msg_pool: Dict[String, List[Float64]]
    var floats_msgs: Dict[String, FloatsMessage]
    
    var float_msg_pool: Dict[String, Float64]
    var float_msgs: Dict[String, Float64Message]
    
    var gate_msg_pool: Dict[String, Bool]
    var gate_msgs: Dict[String, GateMessage]

    var gates_msg_pool: Dict[String, List[Bool]]
    var gates_msgs: Dict[String, GatesMessage]

    var ints_msg_pool: Dict[String, List[Int64]]
    var ints_msgs: Dict[String, IntsMessage]

    var int_msg_pool: Dict[String, Int64]
    var int_msgs: Dict[String, Int64Message]

    var trig_msg_pool: Set[String]
    # Rather than making a TrigMessage struct, we only need a Dict:
    # Keys are the "trig names" that have been pooled, the Bools are
    # whether or not they were retrieved this block.
    var trig_msgs: Dict[String, Bool]

    var trigs_msg_pool: Dict[String, List[Bool]]
    var trigs_msgs: Dict[String, TrigsMessage]
    
    # Text Messages need a List of Strings because one could image sending
    # multiple pieces of information at once, for example multiple file paths
    # to load.
    var text_msg_pool: Dict[String, List[String]]
    var text_msgs: Dict[String, TextMessage]

    fn __init__(out self):

        self.floats_msg_pool = Dict[String, List[Float64]]()
        self.floats_msgs = Dict[String, FloatsMessage]()

        self.float_msg_pool = Dict[String, Float64]()
        self.float_msgs = Dict[String, Float64Message]()

        self.gate_msg_pool = Dict[String, Bool]()
        self.gate_msgs = Dict[String, GateMessage]()

        self.gates_msg_pool = Dict[String, List[Bool]]()
        self.gates_msgs = Dict[String, GatesMessage]()

        self.trig_msg_pool = Set[String]()
        self.trig_msgs = Dict[String, Bool]()

        self.trigs_msg_pool = Dict[String, List[Bool]]()
        self.trigs_msgs = Dict[String, TrigsMessage]()

        self.ints_msg_pool = Dict[String, List[Int64]]()
        self.ints_msgs = Dict[String, IntsMessage]()

        self.int_msg_pool = Dict[String, Int64]()
        self.int_msgs = Dict[String, Int64Message]()
        
        self.text_msg_pool = Dict[String, List[String]]()
        self.text_msgs = Dict[String, TextMessage]()


    # update_* functions add messages to the pool to be transferred at the
    # start of the next audio block. These functions are called from MMMAudioBridge
    # when a message is sent from Python.
    @always_inline
    fn update_float_msg(mut self, key: String, value: Float64):
        self.float_msg_pool[key] = value

    @always_inline
    fn update_floats_msg(mut self, key: String, var values: List[Float64]):
        self.floats_msg_pool[key] = values^

    @always_inline
    fn update_gate_msg(mut self, key: String, value: Bool):
        self.gate_msg_pool[key] = value
    
    @always_inline
    fn update_gates_msg(mut self, key: String, var values: List[Bool]):
        self.gates_msg_pool[key] = values^

    @always_inline
    fn update_trig_msg(mut self, key: String):
        self.trig_msg_pool.add(key)

    @always_inline
    fn update_trigs_msg(mut self, key: String, var values: List[Bool]):
        self.trigs_msg_pool[key] = values^

    @always_inline
    fn update_text_msg(mut self, key: String, var text: List[String]) raises:
        if not key in self.text_msg_pool:
            self.text_msg_pool[key] = List[String]()
        self.text_msg_pool[key].extend(text^)

    @always_inline
    fn update_int_msg(mut self, key: String, value: Int64):
        self.int_msg_pool[key] = value
    
    @always_inline
    fn update_ints_msg(mut self, key: String, var values: List[Int64]):
        self.ints_msg_pool[key] = values^

    fn transfer_msgs(mut self) raises:

        for float_msgs in self.floats_msg_pool.take_items():
            self.floats_msgs[float_msgs.key] = FloatsMessage(float_msgs.value)

        for float_msg in self.float_msg_pool.take_items():
            self.float_msgs[float_msg.key] = Float64Message(float_msg.value)

        for gate_msg in self.gate_msg_pool.take_items():
            self.gate_msgs[gate_msg.key] = GateMessage(gate_msg.value)

        for gates_msg in self.gates_msg_pool.take_items():
            self.gates_msgs[gates_msg.key] = GatesMessage(gates_msg.value)

        for text_msg in self.text_msg_pool.take_items():
            self.text_msgs[text_msg.key] = TextMessage(text_msg.value.copy())

        for int_msg in self.int_msg_pool.take_items():
            self.int_msgs[int_msg.key] = Int64Message(int_msg.value)

        for ints_msg in self.ints_msg_pool.take_items():
            self.ints_msgs[ints_msg.key] = IntsMessage(ints_msg.value)

        for trig_msg_str in self.trig_msg_pool:
            self.trig_msgs[trig_msg_str] = False  # Set retrieved Bool to False initially
        # The other pools are Dicts so "take_items()" empties them, but since
        # trig_msg_pool is a Set, we have to clear it manually:
        self.trig_msg_pool.clear() 

        for trigs_msg in self.trigs_msg_pool.take_items():
            self.trigs_msgs[trigs_msg.key] = TrigsMessage(trigs_msg.value)

    # get_* functions retrieve messages from the Dicts *after* they have
    # been transferred from the pools to the Dicts. These functions are called
    # from a graph (likely via a Messenger instance) to get the latest message values.
    @always_inline
    fn get_float(mut self, ref key: String) raises -> Optional[Float64]:
        if key in self.float_msgs:
            self.float_msgs[key].retrieved = True
            return self.float_msgs[key].value
        return None

    @always_inline
    fn check_float(mut self, ref key: String) -> Bool:
        return self.float_msgs.__contains__(key)

    @always_inline
    fn get_gate(mut self, ref key: String) raises -> Optional[Bool]:
        if key in self.gate_msgs:
            self.gate_msgs[key].retrieved = True
            return self.gate_msgs[key].value
        return None

    @always_inline
    fn check_gate(mut self, ref key: String) -> Bool:
        return self.gate_msgs.__contains__(key)

    @always_inline
    fn get_floats(mut self: Self, ref key: String) raises-> Optional[List[Float64]]:
        if key in self.floats_msgs:
            self.floats_msgs[key].retrieved = True
            # Copy is ok here because it will only copy when there is a
            # new list for it to use, which should be rare. If the user
            # is, like, streaming lists of tons of values, they should
            # be using a different method, such as loading the data into
            # a buffer ahead of time and reading from that.
            return self.floats_msgs[key].value.copy()
        return None
        
    @always_inline
    fn check_floats(mut self, ref key: String) -> Bool:
        return self.floats_msgs.__contains__(key)

    @always_inline
    fn get_gates(mut self: Self, ref key: String) raises-> Optional[List[Bool]]:
        if key in self.gates_msgs:
            self.gates_msgs[key].retrieved = True
            # Copy is ok here because it will only copy when there is a
            # new list for it to use, which should be rare. If the user
            # is, like, streaming lists of tons of values, they should
            # be using a different method, such as loading the data into
            # a buffer ahead of time and reading from that.
            return self.gates_msgs[key].value.copy()
        return None
        
    @always_inline
    fn check_gates(mut self, ref key: String) -> Bool:
        return self.gates_msgs.__contains__(key)
    
    @always_inline
    fn get_trig(mut self, ref key: String) -> Bool:
        if key in self.trig_msgs:
            self.trig_msgs[key] = True
            return True
        return False

    @always_inline
    fn check_trig(mut self, ref key: String) -> Bool:
        return self.trig_msgs.__contains__(key)

    @always_inline
    fn get_trigs(mut self, ref key: String) raises -> Optional[List[Bool]]:
        if key in self.trigs_msgs:
            self.trigs_msgs[key].retrieved = True
            return self.trigs_msgs[key].value.copy()
        return None

    @always_inline
    fn check_trigs(mut self, ref key: String) -> Bool:
        return self.trigs_msgs.__contains__(key)

    # Unlike the other "get_*" functions, this one returns an Optional List of Strings
    # because it doesn't make sense for there to be a default value for text messages.
    @always_inline
    fn get_texts(mut self, ref key: String) raises -> Optional[List[String]]:
        if key in self.text_msgs:
            self.text_msgs[key].retrieved = True
            # Copy here is ok because text messages are expected
            # to be rare, so this shouldn't happen often.
            return self.text_msgs[key].values.copy()
        return None

    @always_inline
    fn check_texts(mut self, ref key: String) -> Bool:
        return self.text_msgs.__contains__(key)

    @always_inline
    fn get_int(mut self, ref key: String) raises -> Optional[Int64]:
        if key in self.int_msgs:
            self.int_msgs[key].retrieved = True
            return self.int_msgs[key].value
        return None

    @always_inline
    fn check_int(mut self, ref key: String) -> Bool:
        return self.int_msgs.__contains__(key)

    @always_inline
    fn get_ints(mut self, ref key: String) raises -> Optional[List[Int64]]:
        if key in self.ints_msgs:
            self.ints_msgs[key].retrieved = True
            return self.ints_msgs[key].value.copy()
        return None

    @always_inline
    fn check_ints(mut self, ref key: String) -> Bool:
        return self.ints_msgs.__contains__(key)

    fn empty_msg_dicts(mut self):
        for float_msgs in self.floats_msgs.take_items():
            if not float_msgs.value.retrieved:
                print("List message was not retrieved this block:", float_msgs.key)

        for float_msg in self.float_msgs.take_items():
            if not float_msg.value.retrieved:
                print("Float message was not retrieved this block:", float_msg.key)

        for gate_msg in self.gate_msgs.take_items():
            if not gate_msg.value.retrieved:
                print("Gate message was not retrieved this block:", gate_msg.key)

        for gates_msg in self.gates_msgs.take_items():
            if not gates_msg.value.retrieved:
                print("Gates message was not retrieved this block:", gates_msg.key)
        
        for trig_msg in self.trig_msgs.take_items():
            if not trig_msg.value: # It wasn't retrieved this block
                print("Trig message", trig_msg.key, "was not retrieved this block.")

        for trigs_msg in self.trigs_msgs.take_items():
            if not trigs_msg.value.retrieved:
                print("Trigs message", trigs_msg.key, "was not retrieved this block.")

        for text_msg in self.text_msgs.take_items():
            if not text_msg.value.retrieved:
                print("Text message", text_msg.key, "was not retrieved this block.")
                for val in text_msg.value.values:
                    print("   Value:", val)

        for int_msg in self.int_msgs.take_items():
            if not int_msg.value.retrieved:
                print("Int message", int_msg.key, "was not retrieved this block.")

        for ints_msg in self.ints_msgs.take_items():
            if not ints_msg.value.retrieved:
                print("Ints message", ints_msg.key, "was not retrieved this block.")

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

    var print_counter: UInt16

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

        self.print_counter = 0

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
    fn print[*Ts: Writable](self, *values: *Ts, n_blocks: UInt16 = 10, sep: StringSlice[StaticConstantOrigin] = " ", end: StringSlice[StaticConstantOrigin] = "\n") -> None:
        if self.top_of_block:
            if self.print_counter % n_blocks == 0:
                @parameter
                for i in range(values.__len__()):
                    print(values[i], end=" ")
                print("")



