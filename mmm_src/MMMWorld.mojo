from python import PythonObject
from mmm_dsp.OscBuffers import OscBuffers
from mmm_dsp.Buffer import Buffer
from mmm_utils.Windows import *
# from mmm_utils.Print import Print
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

    var grab_messages: Int64

    var msg_dict: Dict[String, List[Float64]]
    var text_msg_dict: Dict[String, List[String]]
    var midi_dict: Dict[String, Int64]
    # windows
    var hann_window: Buffer

    var buffers: List[Buffer]

    # var pointer_to_self: UnsafePointer[MMMWorld]
    var last_print_time: Float64

    # it does not like this, not sure why
    # var printer: Print

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

        self.grab_messages = 0

        self.msg_dict = Dict[String, List[Float64]]()
        self.text_msg_dict = Dict[String, List[String]]()
        self.midi_dict = Dict[String, Int64]()

        self.buffers = List[Buffer]()  # Initialize the list of buffers
        # self.pointer_to_self = UnsafePointer[MMMWorld]()  # Create a pointer to self
        # self.printer = Print(self.pointer_to_self)  # Initialize the Print instance
        self.last_print_time = 0.0

        print("MMMWorld initialized with sample rate:", self.sample_rate, "and block size:", self.block_size)

    fn set_channel_count(mut self, num_in_chans: Int64, num_out_chans: Int64):
        self.num_in_chans = num_in_chans
        self.num_out_chans = num_out_chans
        self.sound_in = List[Float64]()
        for _ in range(self.num_in_chans):
            self.sound_in.append(0.0)  # Reinitialize input buffer with zeros

    fn __repr__(self) -> String:
        return "MMMWorld(sample_rate: " + String(self.sample_rate) + ", block_size: " + String(self.block_size) + ")"

    fn send_msg(mut self, key: String, mut list: List[Float64]):
        if key == "mouse_x":
            list[0] = list[0] / self.screen_dims[0]  # Normalize mouse x position
            self.mouse_x = list[0]  # Update mouse x position in the world
        elif key == "mouse_y":
            list[0] = list[0] / self.screen_dims[1]  # Normalize mouse y position
            self.mouse_y = list[0]  # Update mouse y position in the world

        # if key == "thrustmaster":
        #     if list[5] == 1.0:
        #         print("Thrustmaster joystick button pressed")
        else:
            self.msg_dict[key] = list.copy()  # Store a copy of the list to avoid reference issues

    fn get_msg(mut self: Self, key: String) -> Optional[List[Float64]]:

        if self.grab_messages == 1:
            return self.msg_dict.get(key)
        return None

    # fn print_msgs(mut self: Self):
    #     try:
    #         if self.grab_messages == 1:
    #             for key in self.msg_dict.keys():
    #                 print(key, end=": ")
    #                 list = self.msg_dict[key]
    #                 for val in list:
    #                     print(String(val), end=", ")
    #             print()
    #     except Exception:
    #         pass

    fn send_text_msg(mut self, key: String, mut list: List[String]):
        self.text_msg_dict[key] = list.copy()

    fn get_text_msg(mut self: Self, key: String) -> Optional[List[String]]:

        if self.grab_messages == 1:
            return self.text_msg_dict.get(key)
        return None

    fn get_midi(mut self: Self, key: String, chan: Int64 = -1, param: Int64 = -1) -> Optional[List[List[Int64]]]:
        if self.grab_messages == 1:
            if len(self.midi_dict) > 0:
                list = List[List[Int64]]()
                for dict_item in self.midi_dict.items():
                    if dict_item.key.startswith(key):
                        parts = dict_item.key.split("/")
                        if len(parts) == 2:
                            try:
                                if (chan == -1 or Int64(parts[1]) == chan):
                                    lil_list = List[Int64]()
                                    lil_list.append(Int64(parts[1]))
                                    lil_list.append(Int64(dict_item.value))
                                    list.append(lil_list.copy())
                            except:
                                pass
                        if len(parts) == 3:
                            try:
                                if (chan == -1 or Int64(parts[1]) == chan) and (param == -1 or Int64(parts[2]) == param):
                                    lil_list = List[Int64]()
                                    lil_list.append(Int64(parts[1]))
                                    lil_list.append(Int64(parts[2]))
                                    lil_list.append(Int64(dict_item.value))
                                    list.append(lil_list.copy())
                            except:
                                pass
                return list.copy()
        return None

    fn clear_midi(mut self):
        self.midi_dict.clear()

    fn send_midi(mut self, msg: PythonObject) raises :
        if not msg:
            return

        print(msg[0], msg[1])

        self.midi_dict[String(msg[0])] = Int64(msg[1])
    
    fn clear_msgs(mut self):
        self.msg_dict.clear()
        self.midi_dict.clear()
        self.text_msg_dict.clear()

    fn print[T: Writable](mut self, value: T, label: String = "", freq: Float64 = 10.0) -> None:

        current_time = time.perf_counter()
        if current_time - self.last_print_time >= 1.0 / freq:
            self.last_print_time = current_time
            print(label,value)