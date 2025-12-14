from python import PythonObject
from mmm_dsp.Osc import OscBuffers
from mmm_dsp.Buffer import *
from mmm_utils.Windows import *
from mmm_utils.Print import Print
import time
from collections import Set
from mmm_dsp.SincInterpolator import SincInterpolator
from mmm_utils.Messenger import MessengerManager

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
        self.windows = Windows()

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

# Enum-like structs for selecting settings
# ========================================
# once Mojo has enums, these will probably be converted to enums

struct Interp:
    alias none: Int = 0
    alias linear: Int = 1
    alias quad: Int = 2
    alias cubic: Int = 3
    alias lagrange4: Int = 4
    alias sinc: Int = 5

struct WindowType:
    alias rect: Int = 0
    alias hann: Int = 1
    alias hamming: Int = 2
    alias blackman: Int = 3
    alias kaiser: Int = 4
    alias sine: Int = 5

struct OscType:
    alias sine: Int = 0
    alias saw: Int = 1
    alias square: Int = 2
    alias triangle: Int = 3
    alias bandlimited_triangle: Int = 4
    alias bandlimited_saw: Int = 5
    alias bandlimited_square: Int = 6