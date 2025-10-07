from python import PythonObject
from mmm_dsp.OscBuffers import OscBuffers
from mmm_dsp.Buffer import Buffer
from mmm_utils.Windows import *
from mmm_utils.Print import Print
import time

struct MMMWorld(Representable, Movable, Copyable):
    var sample_rate: Float64
    var block_size: Int64
    var osc_buffers: OscBuffers  # Instance of OscBuffers for managing oscillator buffers
    var num_in_chans: Int64
    var num_out_chans: Int64

    var sound_in: List[Float64]

    var screen_dims: List[Float64]  
     
    var os_multiplier: List[Float64]  # List of multipliers for different oscillators

    var mouse_x: Float64
    var mouse_y: Float64

    var block_state: Int64

    var msg_pool: Dict[String, List[List[Float64]]]
    var msg_dict: Dict[String, List[List[Float64]]]

    var text_msg_dict: Dict[String, List[String]]
    var note_ons: List[List[Int64]]
    var note_offs: List[List[Int64]]
    var ccs: List[List[Int64]]
    var bends: List[List[Int64]]
    

    # windows
    var hann_window: Buffer

    var buffers: List[Buffer]

    # var pointer_to_self: UnsafePointer[MMMWorld]
    var last_print_time: Float64
    var print_flag: Int64
    var last_print_flag: Int64

    fn __init__(out self, sample_rate: Float64 = 48000.0, block_size: Int64 = 64, num_in_chans: Int64 = 2, num_out_chans: Int64 = 2):
        self.sample_rate = sample_rate
        self.block_size = block_size
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

        self.msg_pool = Dict[String, List[List[Float64]]]()
        self.msg_dict = Dict[String, List[List[Float64]]]()

        self.text_msg_dict = Dict[String, List[String]]()
        self.note_ons = List[List[Int64]]()
        self.note_offs = List[List[Int64]]()
        self.ccs = List[List[Int64]]()
        self.bends = List[List[Int64]]()

        self.buffers = List[Buffer]()  # Initialize the list of buffers
        self.last_print_time = 0.0
        self.print_flag = 0
        self.last_print_flag = 0

        print("MMMWorld initialized with sample rate:", self.sample_rate, "and block size:", self.block_size)

    fn set_channel_count(mut self, num_in_chans: Int64, num_out_chans: Int64):
        self.num_in_chans = num_in_chans
        self.num_out_chans = num_out_chans
        self.sound_in = List[Float64]()
        for _ in range(self.num_in_chans):
            self.sound_in.append(0.0)  # Reinitialize input buffer with zeros

    fn __repr__(self) -> String:
        return "MMMWorld(sample_rate: " + String(self.sample_rate) + ", block_size: " + String(self.block_size) + ")"

    fn send_msg(mut self, key_vals: PythonObject) raises :
        """ puts a message into the message pool. key_vals is a list where the first item is the key (String) and the rest are Float64 values """
        key = String(key_vals[0])
        var list = List[Float64]()
        for i in range(1, len(key_vals)):
            list.append(Float64(key_vals[i]))
        
        if key == "mouse_x":
            list[0] = list[0] / self.screen_dims[0]  # Normalize mouse x position
            self.mouse_x = list[0]  # Update mouse x position in the world
        elif key == "mouse_y":
            list[0] = list[0] / self.screen_dims[1]  # Normalize mouse y position
            self.mouse_y = list[0]  # Update mouse y position in the world
        else:
            # i wish you knew how difficult these 6 lines of code were
            opt = self.msg_pool.get(key)
            if opt:
                self.msg_pool[key].append(list^)
            else:
                self.msg_pool[key] = List[List[Float64]]()
                self.msg_pool[key].append(list^)

    @always_inline
    fn get_msg(mut self: Self, key: String) -> Optional[List[List[Float64]]]:
        if self.block_state == 0:
            return self.msg_pool.get(key)
        return None

    fn send_text_msg(mut self, key: String, mut list: List[String]):
        self.text_msg_dict[key] = list.copy()

    @always_inline
    fn get_text_msg(mut self: Self, key: String) -> Optional[List[String]]:

        if self.block_state == 0:
            return self.text_msg_dict.get(key)
        return None

    @always_inline
    fn clear_msgs(mut self):
        self.note_ons.clear()
        self.note_offs.clear()
        self.ccs.clear()
        self.bends.clear()
        self.msg_pool.clear()
        self.text_msg_dict.clear()
        self.block_state = 0

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


