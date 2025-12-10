from python import PythonObject
from mmm_dsp.Osc import OscBuffers
from mmm_dsp.Buffer import Buffer
from mmm_utils.Windows import *
from mmm_utils.Print import Print
import time
from collections import Set
from mmm_dsp.SincInterpolator import SincInterpolator

@doc_private
struct BoolMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Bool

    fn __init__(out self, value: Bool):
        self.retrieved = False
        self.value = value

@doc_private
struct BoolsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Bool]

    fn __init__(out self, value: List[Bool]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct FloatMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Float64

    fn __init__(out self, value: Float64):
        self.retrieved = False
        self.value = value

@doc_private
struct FloatsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Float64]

    fn __init__(out self, value: List[Float64]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct IntMessage(Movable, Copyable):
    var retrieved: Bool
    var value: Int64

    fn __init__(out self, value: Int64):
        self.retrieved = False
        self.value = value

@doc_private
struct IntsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Int64]

    fn __init__(out self, value: List[Int64]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct StringMessage(Movable, Copyable):
    var value: String
    var retrieved: Bool

    fn __init__(out self, value: String):
        self.value = value.copy()
        self.retrieved = False

@doc_private
struct StringsMessage(Movable, Copyable):
    var value: List[String]
    var retrieved: Bool

    fn __init__(out self, value: List[String]):
        self.value = value.copy()
        self.retrieved = False

# struct TrigMessage isn't necessary. See MessengerManager for explanation.

@doc_private
struct TrigsMessage(Movable, Copyable):
    var retrieved: Bool
    var value: List[Bool]

    fn __init__(out self, value: List[Bool]):
        self.retrieved = False
        self.value = value.copy()

@doc_private
struct MessengerManager(Movable, Copyable):

    var bool_msg_pool: Dict[String, Bool]
    var bool_msgs: Dict[String, BoolMessage]

    var bools_msg_pool: Dict[String, List[Bool]]
    var bools_msgs: Dict[String, BoolsMessage]

    var float_msg_pool: Dict[String, Float64]
    var float_msgs: Dict[String, FloatMessage]
    
    var floats_msg_pool: Dict[String, List[Float64]]
    var floats_msgs: Dict[String, FloatsMessage]
    
    var int_msg_pool: Dict[String, Int64]
    var int_msgs: Dict[String, IntMessage]

    var ints_msg_pool: Dict[String, List[Int64]]
    var ints_msgs: Dict[String, IntsMessage]

    var string_msg_pool: Dict[String, String]
    var string_msgs: Dict[String, StringMessage]

    var strings_msg_pool: Dict[String, List[String]]
    var strings_msgs: Dict[String, StringsMessage]

    var trig_msg_pool: Set[String]
    # Rather than making a TrigMessage struct, we only need a Dict:
    # Keys are the "trig names" that have been pooled, the Bools are
    # whether or not they were retrieved this block.
    var trig_msgs: Dict[String, Bool]

    var trigs_msg_pool: Dict[String, List[Bool]]
    var trigs_msgs: Dict[String, TrigsMessage]
    
    fn __init__(out self):

        self.bool_msg_pool = Dict[String, Bool]()
        self.bool_msgs = Dict[String, BoolMessage]()

        self.bools_msg_pool = Dict[String, List[Bool]]()
        self.bools_msgs = Dict[String, BoolsMessage]()

        self.float_msg_pool = Dict[String, Float64]()
        self.float_msgs = Dict[String, FloatMessage]()

        self.floats_msg_pool = Dict[String, List[Float64]]()
        self.floats_msgs = Dict[String, FloatsMessage]()

        self.int_msg_pool = Dict[String, Int64]()
        self.int_msgs = Dict[String, IntMessage]()
        
        self.ints_msg_pool = Dict[String, List[Int64]]()
        self.ints_msgs = Dict[String, IntsMessage]()

        self.string_msg_pool = Dict[String, String]()
        self.string_msgs = Dict[String, StringMessage]()

        self.strings_msg_pool = Dict[String, List[String]]()
        self.strings_msgs = Dict[String, StringsMessage]()

        self.trig_msg_pool = Set[String]()
        self.trig_msgs = Dict[String, Bool]()

        self.trigs_msg_pool = Dict[String, List[Bool]]()
        self.trigs_msgs = Dict[String, TrigsMessage]()

    ##### Bool #####
    @always_inline
    fn update_bool_msg(mut self, key: String, value: Bool):
        self.bool_msg_pool[key] = value

    @always_inline
    fn update_bools_msg(mut self, key: String, var value: List[Bool]):
        self.bools_msg_pool[key] = value^

    ##### Float #####
    @always_inline
    fn update_float_msg(mut self, key: String, value: Float64):
        self.float_msg_pool[key] = value

    @always_inline
    fn update_floats_msg(mut self, key: String, var value: List[Float64]):
        self.floats_msg_pool[key] = value^

    ##### Int #####
    @always_inline
    fn update_int_msg(mut self, key: String, value: Int64):
        self.int_msg_pool[key] = value
    
    @always_inline
    fn update_ints_msg(mut self, key: String, var value: List[Int64]):
        self.ints_msg_pool[key] = value^

    ##### String #####
    @always_inline
    fn update_string_msg(mut self, key: String, value: String):
        self.string_msg_pool[key] = value

    @always_inline
    fn update_strings_msg(mut self, key: String, var value: List[String]):
        self.strings_msg_pool[key] = value^

    ##### Trig #####
    @always_inline
    fn update_trig_msg(mut self, var key: String):
        self.trig_msg_pool.add(key^)

    @always_inline
    fn update_trigs_msg(mut self, key: String, var value: List[Bool]):
        self.trigs_msg_pool[key] = value^

    fn transfer_msgs(mut self) raises:

        for bm in self.bool_msg_pool.take_items():
            self.bool_msgs[bm.key] = BoolMessage(bm.value)

        for bsm in self.bools_msg_pool.take_items():
            self.bools_msgs[bsm.key] = BoolsMessage(bsm.value)

        for fm in self.float_msg_pool.take_items():
            self.float_msgs[fm.key] = FloatMessage(fm.value)

        for fsm in self.floats_msg_pool.take_items():
            self.floats_msgs[fsm.key] = FloatsMessage(fsm.value)

        for im in self.int_msg_pool.take_items():
            self.int_msgs[im.key] = IntMessage(im.value)

        for ism in self.ints_msg_pool.take_items():
            self.ints_msgs[ism.key] = IntsMessage(ism.value)

        for sm in self.string_msg_pool.take_items():
            self.string_msgs[sm.key] = StringMessage(sm.value)

        for ssm in self.strings_msg_pool.take_items():
            self.strings_msgs[ssm.key] = StringsMessage(ssm.value)

        for tm in self.trig_msg_pool:
            self.trig_msgs[tm] = False  # Set retrieved Bool to False initially
        # The other pools are Dicts so "take_items()" empties them, but since
        # trig_msg_pool is a Set, we have to clear it manually:
        self.trig_msg_pool.clear() 

        for tsm in self.trigs_msg_pool.take_items():
            self.trigs_msgs[tsm.key] = TrigsMessage(tsm.value)

    # get_* functions retrieve messages from the Dicts *after* they have
    # been transferred from the pools to the Dicts. These functions are called
    # from a graph (likely via a Messenger instance) to get the latest message values.
    @always_inline
    fn get_bool(mut self, ref key: String) raises -> Optional[Bool]:
        if key in self.bool_msgs:
            self.bool_msgs[key].retrieved = True
            return self.bool_msgs[key].value
        return None

    @always_inline
    fn get_bools(mut self: Self, ref key: String) raises-> Optional[List[Bool]]:
        if key in self.bools_msgs:
            self.bools_msgs[key].retrieved = True
            # Copy is ok here because it will only copy when there is a
            # new list for it to use, which should be rare. If the user
            # is, like, streaming lists of tons of values, they should
            # be using a different method, such as loading the data into
            # a buffer ahead of time and reading from that.
            return self.bools_msgs[key].value.copy()
        return None
    
    @always_inline
    fn get_float(mut self, ref key: String) raises -> Optional[Float64]:
        if key in self.float_msgs:
            self.float_msgs[key].retrieved = True
            return self.float_msgs[key].value
        return None

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
    fn get_int(mut self, ref key: String) raises -> Optional[Int64]:
        if key in self.int_msgs:
            self.int_msgs[key].retrieved = True
            return self.int_msgs[key].value
        return None

    @always_inline
    fn get_ints(mut self, ref key: String) raises -> Optional[List[Int64]]:
        if key in self.ints_msgs:
            self.ints_msgs[key].retrieved = True
            return self.ints_msgs[key].value.copy()
        return None

    @always_inline
    fn get_string(mut self, ref key: String) raises -> Optional[String]:
        if key in self.string_msgs:
            self.string_msgs[key].retrieved = True
            return self.string_msgs[key].value
        return None

    @always_inline
    fn get_strings(mut self, ref key: String) raises -> Optional[List[String]]:
        if key in self.strings_msgs:
            self.strings_msgs[key].retrieved = True
            return self.strings_msgs[key].value.copy()
        return None

    @always_inline
    fn get_trig(mut self, key: String) -> Bool:
        if key in self.trig_msgs:
            self.trig_msgs[key] = True
            return True
        return False

    @always_inline
    fn get_trigs(mut self, key: String) raises -> Optional[List[Bool]]:
        if key in self.trigs_msgs:
            self.trigs_msgs[key].retrieved = True
            return self.trigs_msgs[key].value.copy()
        return None

    fn empty_msg_dicts(mut self):
        for bool_msg in self.bool_msgs.take_items():
            if not bool_msg.value.retrieved:
                print("Bool message was not retrieved this block:", bool_msg.key)

        for bools_msg in self.bools_msgs.take_items():
            if not bools_msg.value.retrieved:
                print("Bools message was not retrieved this block:", bools_msg.key)

        for float_msg in self.float_msgs.take_items():
            if not float_msg.value.retrieved:
                print("Float message was not retrieved this block:", float_msg.key)

        for floats_msg in self.floats_msgs.take_items():
            if not floats_msg.value.retrieved:
                print("Floats message was not retrieved this block:", floats_msg.key)

        for int_msg in self.int_msgs.take_items():
            if not int_msg.value.retrieved:
                print("Int message was not retrieved this block:", int_msg.key)

        for ints_msg in self.ints_msgs.take_items():
            if not ints_msg.value.retrieved:
                print("Ints message was not retrieved this block:", ints_msg.key)

        for string_msg in self.string_msgs.take_items():
            if not string_msg.value.retrieved:
                print("String message was not retrieved this block:", string_msg.key)
        
        for strings_msg in self.strings_msgs.take_items():
            if not strings_msg.value.retrieved:
                print("Strings message was not retrieved this block:", strings_msg.key)

        for tm in self.trig_msgs.take_items():
            if not tm.value:
                print("Trig message was not retrieved this block:", tm.key)

        for trigs_msg in self.trigs_msgs.take_items():
            if not trigs_msg.value.retrieved:
                print("Trigs message was not retrieved this block:", trigs_msg.key)


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
    var windows: Windows

    var sinc_interpolator: SincInterpolator[4, 14]

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
        self.windows = Windows(UnsafePointer(to=self),2048)

        self.os_multiplier = List[Float64]()  # Initialize the list of multipliers
        for i in range(5):  # Initialize multipliers for oversampling ratios
            self.os_multiplier.append(1.0 / (2 ** i))  # Example multipliers, can be adjusted as needed

        # I don't know why, but objects don't see these as updated? maybe it is copying the world when I pass it?
        self.mouse_x = 0.0
        self.mouse_y = 0.0
        self.screen_dims = List[Float64](0.0, 0.0)  # Initialize screen dimensions with zeros

        self.block_state = 0

        self.last_print_time = 0.0
        self.print_flag = 0
        self.last_print_flag = 0

        self.messengerManager = MessengerManager()

        self.print_counter = 0

        self.sinc_interpolator = SincInterpolator[4,14]()

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



