from python import PythonObject
import time
from collections import Set
from mmm_audio import *

comptime MFloat[N: Int = 1] = SIMD[DType.float64, N]
comptime MInt[N: Int = 1] = SIMD[DType.int64, N]
comptime MBool[N: Int = 1] = SIMD[DType.bool, N]
comptime World = UnsafePointer[mut=True, MMMWorld, MutExternalOrigin]

struct MMMWorld(Movable, Copyable):
    """The MMMWorld struct holds global audio processing parameters and state.

    In pretty much all usage, don't edit this struct.
    """
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

    # var pointer_to_self: World
    var last_print_time: Float64
    var print_flag: Int64
    var last_print_flag: Int64

    var print_counter: UInt16

    fn __init__(out self, sample_rate: Float64 = 48000.0, block_size: Int64 = 64, num_in_chans: Int64 = 2, num_out_chans: Int64 = 2):
        """Initializes the MMMWorld struct.

        Args:
            sample_rate: The audio sample rate.
            block_size: The audio block size.
            num_in_chans: The number of input channels.
            num_out_chans: The number of output channels.
        """
        
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
        self.screen_dims = [0.0, 0.0]  # Initialize screen dimensions with zeros

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
        """Sets the number of input and output channels.

        Args:
            num_in_chans: The number of input channels.
            num_out_chans: The number of output channels.
        """
        self.num_in_chans = num_in_chans
        self.num_out_chans = num_out_chans
        self.sound_in = List[Float64]()
        for _ in range(self.num_in_chans):
            self.sound_in.append(0.0)  # Reinitialize input buffer with zeros

    @always_inline
    fn print[*Ts: Writable](self, *values: *Ts, n_blocks: UInt16 = 10, sep: StringSlice[StaticConstantOrigin] = " ", end: StringSlice[StaticConstantOrigin] = "\n") -> None:
        """Print values to the console at the top of the audio block every n_blocks.

        Parameters:
            Ts: Types of the values to print. Can be of any type that implements Mojo's `Writable` trait. This parameter is inferred by the values passed to the function. The user doesn't need to specify it.

        Args:
            values: Values to print. Can be of any type that implements Mojo's `Writable` trait. This is a "variadic" argument meaning that the user can pass in any number of values (not as a list, just as comma separated arguments).
            n_blocks: Number of audio blocks between prints. Must be specified using the keyword argument.
            sep: Separator string between values. Must be specified using the keyword argument.
            end: End string to print after all values. Must be specified using the keyword argument.
        """
        
        if self.top_of_block:
            if self.print_counter % n_blocks == 0:
                @parameter
                for i in range(values.__len__()):
                    print(values[i], end=sep if i < values.__len__() - 1 else end)

# Enum-like structs for selecting settings
# ========================================
# once Mojo has enums, these will probably be converted to enums

struct Interp:
    """Interpolation types for use in various UGens.

    Specify an interpolation type by typing it explicitly.
    For example, to specify linear interpolation, one could use the number `1`, 
    but it is clearer to type `Interp.linear`.

    | Interpolation Type | Value | Notes                                        |
    | ------------------ | ----- | -------------------------------------------- |
    | Interp.none        | 0     |                                              |
    | Interp.linear      | 1     |                                              |
    | Interp.quad        | 2     |                                              |
    | Interp.cubic       | 3     |                                              |
    | Interp.lagrange4   | 4     |                                              |
    | Interp.sinc        | 5     | Should only be used with oscillators         |
    
    """
    comptime none: Int = 0
    comptime linear: Int = 1
    comptime quad: Int = 2
    comptime cubic: Int = 3
    comptime lagrange4: Int = 4
    comptime sinc: Int = 5

struct WindowType:
    """Window types for predefined windows found in world[].windows.

    Specify a window type by typing it explicitly.
    For example, to specify a hann window, one could use the number `1`, 
    but it is clearer to type `WindowType.hann`.

    | Window Type         | Value |
    | ------------------- | ----- |
    | WindowType.rect     | 0     |
    | WindowType.hann     | 1     |
    | WindowType.hamming  | 2     |
    | WindowType.blackman | 3     |
    | WindowType.kaiser   | 4     |
    | WindowType.sine     | 5     |
    | WindowType.tri      | 6     |
    | WindowType.pan2     | 7     |
    """

    comptime rect: Int = 0
    comptime hann: Int = 1
    comptime hamming: Int = 2
    comptime blackman: Int = 3
    comptime kaiser: Int = 4
    comptime sine: Int = 5
    comptime tri: Int = 6
    comptime pan2: Int = 7

struct OscType:
    """Oscillator types for selecting waveform types.

    Specify an oscillator type by typing it explicitly.
    For example, to specify a sine, one could use the number `0`, 
    but it is clearer to type `OscType.sine`.

    | Oscillator Type              | Value |
    | ---------------------------- | ----- |
    | OscType.sine                 | 0     |
    | OscType.triangle             | 1     |
    | OscType.saw                  | 2     |
    | OscType.square               | 3     |
    | OscType.bandlimited_triangle | 4     |
    | OscType.bandlimited_saw      | 5     |
    | OscType.bandlimited_square.  | 6     |
    """
    comptime sine: Int = 0
    comptime triangle: Int = 1
    comptime saw: Int = 2
    comptime square: Int = 3
    comptime bandlimited_triangle: Int = 4
    comptime bandlimited_saw: Int = 5
    comptime bandlimited_square: Int = 6