from mmm_audio import *
from math import floor

# Eventually, I think it would be better for the user defined BufferProcessable
# struct to be where the `window_size` is set as a parameter and then this value
# can be retrieved
# by the BufferedProcess struct. Mojo currently doesn't allow this traits to have
# parameters. I think `hop_size` would still be a parameter of the BufferedProcess struct.
trait BufferedProcessable(Movable, Copyable):
    """Trait that user structs must implement to be used with a BufferedProcess.
    
    Requires two functions:

    - `next_window(buffer: List[Float64]) -> None`: This function is called when enough samples have been buffered.
      The user can process the input buffer in place meaning that the samples you want to return to the output need
      to replace the samples that you receive in the input list.
    
    - `get_messages() -> None`: This function is called at the top of each audio block to allow the user to retrieve any messages
      they may have sent to this process. Put your [Messenger](Messenger.md) message retrieval code here. (e.g. `self.messenger.update(self.param, "param_name")`)
    """
    fn next_window(mut self, mut buffer: List[Float64]) -> None:
        return None

    fn next_stereo_window(mut self, mut buffer: List[SIMD[DType.float64, 2]]) -> None:
        return None
    
    fn get_messages(mut self) -> None:
        return None

struct BufferedInput[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Int = WindowType.hann](Movable, Copyable):
    """Buffers input samples and hands them over to be processed in 'windows'.

    Parameters:
        T: A user defined struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait.
        window_size: The size of the window that is passed to the user defined struct for processing.
        hop_size: The number of samples between each call to the user defined struct's `next_window()` function.
        input_window_shape: Window shape to apply to the input samples before passing them to the user defined struct. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann).
    """
    var world: LegacyUnsafePointer[MMMWorld]
    var input_buffer: List[Float64]
    var passing_buffer: List[Float64]
    var input_buffer_write_head: Int
    var hop_counter: Int
    var process: T
    var input_attenuation_window: List[Float64]

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld], var process: T, hop_start: Int = 0):
        """Initializes a BufferedInput struct.

        Args:
            world: A pointer to the MMMWorld.
            process: A user defined struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait.
            hop_start: The initial value of the hop counter. Default is 0. This can be used to offset the processing start time, if for example, you need to offset the start time of the first frame. This can be useful when separating windows into separate `BufferedInput`s, and therefore separate audio streams, so that each window could be routed or processed with different FX chains.

        Returns:
            An initialized `BufferedInput` struct.
        """
        
        self.world = world
        self.input_buffer_write_head = 0
        self.hop_counter = hop_start
        self.process = process^
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.passing_buffer = List[Float64](length=window_size, fill=0.0)

        self.input_attenuation_window = Windows.make_window[input_window_shape](window_size)

    fn next(mut self, input: Float64) -> None:
        """Process the next input sample and return the next output sample.
        
        This function is called in the audio processing loop for each input sample. It buffers the input samples,
        and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

        Args:
            input: The next input sample to process.
        """
        if self.world[].top_of_block:
            self.process.get_messages()
    
        self.input_buffer[self.input_buffer_write_head] = input
        self.input_buffer[self.input_buffer_write_head + window_size] = input
        self.input_buffer_write_head = (self.input_buffer_write_head + 1) % window_size
        
        if self.hop_counter == 0:

            for i in range(window_size):
                self.passing_buffer[i] = self.input_buffer[self.input_buffer_write_head + i] * self.input_attenuation_window[i]

            self.process.next_window(self.passing_buffer)
    
        self.hop_counter = (self.hop_counter + 1) % hop_size


struct BufferedProcess[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Int = WindowType.hann, output_window_shape: Int = WindowType.hann](Movable, Copyable):
    """Buffers input samples and hands them over to be processed in 'windows'.

    Parameters:
        T: A user defined struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait.
        window_size: The size of the window that is passed to the user defined struct for processing.
        hop_size: The number of samples between each call to the user defined struct's `next_window()` function.
        input_window_shape: Window shape to apply to the input samples before passing them to the user defined struct. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann).
        output_window_shape: Window shape to apply to the output samples after processing by the user defined struct. Use comptime variables from [WindowType](MMMWorld.md/#struct-windowtype) struct (e.g. WindowType.hann).
    """
    var world: LegacyUnsafePointer[MMMWorld]
    var input_buffer: List[Float64]
    var passing_buffer: List[Float64]
    var output_buffer: List[Float64]

    var st_input_buffer: List[SIMD[DType.float64,2]]
    var st_passing_buffer: List[SIMD[DType.float64,2]]
    var st_output_buffer: List[SIMD[DType.float64,2]]

    var input_buffer_write_head: Int
    var read_head: Int
    var hop_counter: Int
    var process: T
    var output_buffer_write_head: Int
    var input_attenuation_window: List[Float64]
    var output_attenuation_window: List[Float64]

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld], var process: T, hop_start: Int = 0):
        """Initializes a BufferedProcess struct.

        Args:
            world: A pointer to the MMMWorld.
            process: A user defined struct that implements the BufferedProcessable trait.
            hop_start: The initial value of the hop counter. Default is 0. This can be used to offset the processing start time, if for example, you need to offset the start time of the first frame. This can be useful when separating windows into separate BufferedProcesses, and therefore separate audio streams, so that each window could be routed or processed with different FX chains.

        Returns:
            An initialized BufferedProcess struct.
        """
        
        self.world = world
        self.input_buffer_write_head = 0
        self.output_buffer_write_head = 0
        self.hop_counter = hop_start
        self.read_head = 0
        self.process = process^
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.passing_buffer = List[Float64](length=window_size, fill=0.0)
        self.output_buffer = List[Float64](length=window_size, fill=0.0)

        self.st_input_buffer = List[SIMD[DType.float64,2]](length=window_size * 2, fill=0.0)
        self.st_passing_buffer = List[SIMD[DType.float64,2]](length=window_size, fill=0.0)
        self.st_output_buffer = List[SIMD[DType.float64,2]](length=window_size, fill=0.0)
        
        self.input_attenuation_window = Windows.make_window[input_window_shape](window_size)
        self.output_attenuation_window = Windows.make_window[output_window_shape](window_size)

    fn next(mut self, input: Float64) -> Float64:
        """Process the next input sample and return the next output sample.
        
        This function is called in the audio processing loop for each input sample. It buffers the input samples,
        and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

        Args:
            input: The next input sample to process.
        
        Returns:
            The next output sample.
        """
        if self.world[].top_of_block:
            self.process.get_messages()
    
        self.input_buffer[self.input_buffer_write_head] = input
        self.input_buffer[self.input_buffer_write_head + window_size] = input
        self.input_buffer_write_head = (self.input_buffer_write_head + 1) % window_size
        
        if self.hop_counter == 0:

            for i in range(window_size):
                self.passing_buffer[i] = self.input_buffer[self.input_buffer_write_head + i] * self.input_attenuation_window[i]

            self.process.next_window(self.passing_buffer)

            for i in range(window_size):
                self.output_buffer[(self.output_buffer_write_head + i) % window_size] += self.passing_buffer[i] * self.output_attenuation_window[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.output_buffer[self.read_head]
        self.output_buffer[self.read_head] = 0.0

        self.read_head = (self.read_head + 1) % window_size
        return outval

    fn next_stereo(mut self, input: SIMD[DType.float64,2]) -> SIMD[DType.float64,2]:
        """Process the next input sample and return the next output sample.
        
        This function is called in the audio processing loop for each input sample. It buffers the input samples,
        and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

        Args:
            input: The next input sample to process.
        
        Returns:
            The next output sample.
        """
        if self.world[].top_of_block:
            self.process.get_messages()

        self.st_input_buffer[self.input_buffer_write_head] = input
        self.st_input_buffer[self.input_buffer_write_head + window_size] = input
        self.input_buffer_write_head = (self.input_buffer_write_head + 1) % window_size
        
        if self.hop_counter == 0:

            for i in range(window_size):
                self.st_passing_buffer[i] = self.st_input_buffer[self.input_buffer_write_head + i] * self.input_attenuation_window[i]

            self.process.next_stereo_window(self.st_passing_buffer)

            for i in range(window_size):
                self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] += self.st_passing_buffer[i] * self.output_attenuation_window[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.st_output_buffer[self.read_head]
        self.st_output_buffer[self.read_head] = 0.0

        self.read_head = (self.read_head + 1) % window_size
        return outval

    fn next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, chan: Int = 0) -> Float64:
        """Used for non-real-time, buffer-based, processing. At the onset of the next window, reads a block of window_size samples from the provided buffer, starting at the given phase and channel. Phase values between zero and one will read samples within the provided buffer. If the provided phase tries to read samples with an index below zero or above the duration of the buffer, zeros will be returned.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to start reading from the buffer.
            chan: The channel to read from the buffer.
        
        Returns:
            The next output sample.
        """
        
        if self.hop_counter == 0:

            for i in range(window_size):
                index = phase * buffer.num_frames_f64 + i * buffer.sample_rate / self.world[].sample_rate
                self.passing_buffer[i] = ListInterpolator.read_none[bWrap=False](buffer.data[chan], index) * self.input_attenuation_window[i]

            self.process.next_window(self.passing_buffer)

            for i in range(window_size):
                self.output_buffer[(self.output_buffer_write_head + i) % window_size] += self.passing_buffer[i] * self.output_attenuation_window[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.output_buffer[self.read_head]
        self.output_buffer[self.read_head] = 0.0
        
        self.read_head = (self.read_head + 1) % window_size
        return outval

    fn next_from_stereo_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> SIMD[DType.float64,2]:
        """Used for non-real-time, buffer-based, processing of stereo files. At the onset of the next window, reads a window_size block of samples from the provided buffer, starting at the given phase and channel. Phase values between zero and one will read samples within the provided buffer. If the provided phase results in reading samples with an index below zero or above the duration of the buffer, zeros will be returned.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer.
            start_chan: The first channel to read from the buffer. The second channel will be start_chan + 1.
        
        Returns:
            The next output sample.
        """
        
        if self.hop_counter == 0:
           
            for i in range(window_size):
                index = floor(phase * buffer.num_frames_f64) + i
                self.st_passing_buffer[i][0] = ListInterpolator.read_none[bWrap=False](buffer.data[start_chan], index) * self.input_attenuation_window[i]
                self.st_passing_buffer[i][1] = ListInterpolator.read_none[bWrap=False](buffer.data[start_chan + 1], index) * self.input_attenuation_window[i]

            self.process.next_stereo_window(self.st_passing_buffer)

            for i in range(window_size):
                self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] += self.st_passing_buffer[i] * self.output_attenuation_window[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.st_output_buffer[self.read_head]
        self.st_output_buffer[self.read_head] = 0.0

        self.read_head = (self.read_head + 1) % window_size
        return outval