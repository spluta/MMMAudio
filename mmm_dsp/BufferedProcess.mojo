from mmm_src.MMMWorld import *
from mmm_utils.Windows import *
from math import floor
from mmm_dsp.Buffer import *

# Eventually, I think it would be better for the user defined BufferProcessable
# struct to be where the `window_size` is set as a parameter and then this value
# can be retrieved
# by the BufferedProcess struct. Mojo currently doesn't allow this traits to have
# parameters. I think `hop_size` would still be a parameter of the BufferedProcess struct.
trait BufferedProcessable(Movable, Copyable):
    """Trait that user structs must implement to be used with a BufferedProcess.
    
    Requires two functions:
    - next_window(buffer: List[Float64]) -> None: This function is called when enough samples have been buffered.
      The user can process the input buffer in place meaning that the samples you want to return to the output need
      to replace the samples that you receive in the input list.
    - get_messages() -> None: This function is called at the top of each audio block to allow the user to retrieve any messages
      they may have sent to this process. Put your message retrieval code here. (e.g. `self.messenger.update(self.param, "param_name")`)
    """
    fn next_window(mut self, mut buffer: List[Float64]) -> None:
        return None

    fn next_stereo_window(mut self, mut buffer: List[SIMD[DType.float64, 2]]) -> None:
        return None
    
    fn get_messages(mut self) -> None:
        return None

struct BufferedInput[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Optional[Int] = None](Movable, Copyable):
    """Buffers input samples and hands them over to be processed in 'windows'.
    
    BufferedInput struct handles buffering of input samples and handing them as "windows" 
    to a user defined struct for processing (The user defined struct must implement the 
    BufferedProcessable trait). The user defined struct's `next_window()` function is called every
    `hop_size` samples. BufferedInput passes the user defined struct a List of `window_size` samples. 
    The user can process can do whatever they want with the samples in the List and then must replace the 
    values in the List with the values.

    Parameters:
        T: A user defined struct that implements the BufferedProcessable trait.
        window_size: The size of the window that is passed to the user defined struct for processing. The default is 1024 samples.
        hop_size: The number of samples between each call to the user defined struct's `next_window()` function. The default is 512 samples.
        input_window_shape: Optional window shape to apply to the input samples before passing them to the user defined struct. Use alias variables from WindowType struct (e.g. WindowType.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
    """
    var world: UnsafePointer[MMMWorld]
    var input_buffer: List[Float64]
    var passing_buffer: List[Float64]
    var input_buffer_write_head: Int
    var hop_counter: Int
    var process: T
    var input_attenuation_window: List[Float64]

    fn __init__(out self, world: UnsafePointer[MMMWorld], var process: T, hop_start: Int = 0):
        """Initializes a BufferedInput struct.

        Args:
            w: A pointer to the MMMWorld.
            process: A user defined struct that implements the BufferedProcessable trait.
            hop_start: The initial value of the hop counter. Default is 0. This can be used to offset the processing start time, if for example, you need to offset the start time of the first frame. This can be useful when separating windows into separate BufferedProcesses, and therefore separate audio streams, so that each window could be routed or processed with different FX chains.

        Returns:
            An initialized BufferedInput struct.
        """
        
        self.world = world
        self.input_buffer_write_head = 0
        self.hop_counter = hop_start
        self.process = process^
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.passing_buffer = List[Float64](length=window_size, fill=0.0)

        @parameter
        if input_window_shape == WindowType.hann:
            self.input_attenuation_window = hann_window(window_size)
        elif input_window_shape == WindowType.hamming:
            self.input_attenuation_window = hamming_window(window_size)
        elif input_window_shape == WindowType.blackman:
            self.input_attenuation_window = blackman_window(window_size)
        elif input_window_shape == WindowType.sine:
            self.input_attenuation_window = sine_window(window_size)
        else:
            # never used, just allocate a bunch of zeros
            self.input_attenuation_window = List[Float64](length=window_size, fill=0.0)

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

            @parameter
            if input_window_shape:
                # @parameter # for some reason these slow compilation down a lot
                for i in range(window_size):
                    self.passing_buffer[i] = self.input_buffer[self.input_buffer_write_head + i] * self.input_attenuation_window[i]
            else:
                # @parameter
                for i in range(window_size):
                    self.passing_buffer[i] = self.input_buffer[self.input_buffer_write_head + i]

            self.process.next_window(self.passing_buffer)
    
        self.hop_counter = (self.hop_counter + 1) % hop_size


struct BufferedProcess[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Optional[Int] = None, output_window_shape: Optional[Int] = None](Movable, Copyable):
    """Buffers input samples and hands them over to be processed in 'windows'.
    
    BufferedProcess struct handles buffering of input samples and handing them as "windows" 
    to a user defined struct for processing (The user defined struct must implement the 
    BufferedProcessable trait). The user defined struct's `next_window()` function is called every
    `hop_size` samples. BufferedProcess passes the user defined struct a List of `window_size` samples. 
    The user can process can do whatever they want with the samples in the List and then must replace the 
    values in the List with the values.

    Parameters:
        T: A user defined struct that implements the BufferedProcessable trait.
        window_size: The size of the window that is passed to the user defined struct for processing. The default is 1024 samples.
        hop_size: The number of samples between each call to the user defined struct's `next_window()` function. The default is 512 samples.
        input_window_shape: Optional window shape to apply to the input samples before passing them to the user defined struct. Use alias variables from WindowType struct (e.g. WindowType.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
        output_window_shape: Optional window shape to apply to the output samples after processing by the user defined struct. Use alias variables from WindowType struct (e.g. WindowType.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
    """
    var world: UnsafePointer[MMMWorld]
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

    fn __init__(out self, world: UnsafePointer[MMMWorld], var process: T, hop_start: Int = 0):
        """Initializes a BufferedProcess struct.

        Args:
            w: A pointer to the MMMWorld.
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

        @parameter
        if input_window_shape == WindowType.hann:
            self.input_attenuation_window = hann_window(window_size)
        elif input_window_shape == WindowType.hamming:
            self.input_attenuation_window = hamming_window(window_size)
        elif input_window_shape == WindowType.blackman:
            self.input_attenuation_window = blackman_window(window_size)
        elif input_window_shape == WindowType.sine:
            self.input_attenuation_window = sine_window(window_size)
        else:
            # never used, just allocate a bunch of zeros
            self.input_attenuation_window = List[Float64](length=window_size, fill=0.0)

        @parameter
        if output_window_shape == WindowType.hann:
            self.output_attenuation_window = hann_window(window_size)
        elif output_window_shape == WindowType.hamming:
            self.output_attenuation_window = hamming_window(window_size)
        elif output_window_shape == WindowType.blackman:
            self.output_attenuation_window = blackman_window(window_size)
        elif output_window_shape == WindowType.sine:
            self.output_attenuation_window = sine_window(window_size)
        else:
            # never used, just allocate a bunch of zeros
            self.output_attenuation_window = List[Float64](length=window_size, fill=0.0)

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

            @parameter
            if input_window_shape:
                # @parameter # for some reason these slow compilation down a lot
                for i in range(window_size):
                    self.passing_buffer[i] = self.input_buffer[self.input_buffer_write_head + i] * self.input_attenuation_window[i]
            else:
                # @parameter
                for i in range(window_size):
                    self.passing_buffer[i] = self.input_buffer[self.input_buffer_write_head + i]

            self.process.next_window(self.passing_buffer)

            @parameter
            if output_window_shape:
                # @parameter
                for i in range(window_size):
                    self.passing_buffer[i] *= self.output_attenuation_window[i]

            for i in range(window_size):
                self.output_buffer[(self.output_buffer_write_head + i) % window_size] += self.passing_buffer[i]

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

            @parameter
            if input_window_shape:
                # @parameter # for some reason these slow compilation down a lot
                for i in range(window_size):
                    self.st_passing_buffer[i] = self.st_input_buffer[self.input_buffer_write_head + i] * self.input_attenuation_window[i]
            else:
                # @parameter
                for i in range(window_size):
                    self.st_passing_buffer[i] = self.st_input_buffer[self.input_buffer_write_head + i]

            self.process.next_stereo_window(self.st_passing_buffer)

            @parameter
            if output_window_shape:
                # @parameter
                for i in range(window_size):
                    self.st_passing_buffer[i] *= self.output_attenuation_window[i]

            for i in range(window_size):
                self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] += self.st_passing_buffer[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.st_output_buffer[self.read_head]
        self.st_output_buffer[self.read_head] = 0.0

        self.read_head = (self.read_head + 1) % window_size
        return outval

    fn next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> Float64:
        """Used for non-real-time, buffer-based, processing. At the onset of the next window, reads a block of window_size samples from the provided buffer, starting at the given phase and channel. Phase values between zero and one will read samples within the provided buffer. If the provided phase tries to read samples with an index below zero or above the duration of the buffer, zeros will be returned.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to start reading from the buffer.
            start_chan: The first channel to read from the buffer.
        
        Returns:
            The next output sample.
        """
        
        if self.hop_counter == 0:
           
           var num_frames_f: Float64 = Float64(buffer.num_frames)

            @parameter
            if input_window_shape:
                for i in range(window_size):
                    index = phase * num_frames_f + i * buffer.sample_rate / self.world[].sample_rate
                    # setting the index bounds to num_frames -2 to avoid reading beyond the end of the buffer when interpolation is used
                    if index < num_frames_f - 2.0 and index >= 0:
                        self.passing_buffer[i] = read_none(buffer.data[0], index) * self.input_attenuation_window[i]
                    else:
                        self.passing_buffer[i] = 0.0
            else:
                for i in range(window_size):
                    index = phase * buffer.num_frames + i * buffer.sample_rate / self.world[].sample_rate
                    if index < buffer.num_frames - 2 and index >= 0:
                        self.passing_buffer[i] = buffer.read_index(start_chan, index) * self.input_attenuation_window[i]
                    else:
                        self.passing_buffer[i] = 0.0

            self.process.next_window(self.passing_buffer)

            @parameter
            if output_window_shape:
                for i in range(window_size):
                    self.passing_buffer[i] *= self.output_attenuation_window[i]

            for i in range(window_size):
                self.output_buffer[(self.output_buffer_write_head + i) % window_size] += self.passing_buffer[i]

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
            start_chan: The firstchannel to read from the buffer.
        
        Returns:
            The next output sample.
        """
        
        if self.hop_counter == 0:
           
            @parameter
            if input_window_shape:
                for i in range(window_size):
                    index = floor(phase * buffer.num_frames) + i
                    if index < buffer.num_frames and index >= 0:
                        self.st_passing_buffer[i] = buffer.read_index[2](start_chan, index) * self.input_attenuation_window[i]
                    else:
                        self.st_passing_buffer[i] = 0.0
            else:
                for i in range(window_size):
                    index = floor(phase * buffer.num_frames) + i
                    if index < buffer.num_frames and index >= 0:
                        self.st_passing_buffer[i] = buffer.read_index[2](start_chan, index) * self.input_attenuation_window[i]
                    else:
                        self.st_passing_buffer[i] = 0.0

            self.process.next_stereo_window(self.st_passing_buffer)

            @parameter
            if output_window_shape:
                for i in range(window_size):
                    self.st_passing_buffer[i] *= self.output_attenuation_window[i]

            for i in range(window_size):
                self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] += self.st_passing_buffer[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.st_output_buffer[self.read_head]
        self.st_output_buffer[self.read_head] = 0.0

        self.read_head = (self.read_head + 1) % window_size
        return outval