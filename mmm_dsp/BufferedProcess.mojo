from mmm_src.MMMWorld import *
from mmm_utils.Windows import *
from math import floor

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
    fn next_window(mut self, mut buffer: List[Float64]) -> None:...
    fn get_messages(mut self) -> None:...

struct BufferedProcess[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Optional[Int] = None, output_window_shape: Optional[Int] = None,overlap_output: Bool = True](Movable, Copyable):
    """Buffers input samples and hands them over to be processed in 'windows.'
    
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
        input_window_shape: Optional window shape to apply to the input samples before passing them to the user defined struct.
                            Use alias variables from WindowTypes struct (e.g. WindowTypes.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
        output_window_shape: Optional window shape to apply to the output samples after processing by the user defined struct.
                            Use alias variables from WindowTypes struct (e.g. WindowTypes.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
        overlap_output: If True, overlapping output samples (because hop_size < window_size) are summed together. If False, overlapping output samples overwrite previous samples. 
                            This would be useful to set to False if the user defined processing is doing something like pitch 
                            analysis and replacing all the values in the received List with the detected pitch value. In this case,
                            summing would not make sense (neither would windowing the output) because it would be doing math on the 
                            pitch values that you want to just stay as they are. The default is True.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var input_buffer: List[Float64]
    var passing_buffer: List[Float64]
    var output_buffer: List[Float64]
    var input_buffer_write_head: Int
    var read_head: Int
    var hop_counter: Int
    var process: T
    var output_buffer_write_head: Int
    var p: Print
    var input_attenuation_window: List[Float64]
    var output_attenuation_window: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], var process: T, hop_start: Int = 0):
        """Initializes a BufferedProcess struct.

        Args:
            world_ptr: A pointer to the MMMWorld.
            process: A user defined struct that implements the BufferedProcessable trait.

        Returns:
            An initialized BufferedProcess struct.
        """
        
        self.world_ptr = world_ptr
        self.input_buffer_write_head = 0
        self.output_buffer_write_head = 0
        self.hop_counter = hop_start
        self.read_head = 0
        self.process = process^
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.passing_buffer = List[Float64](length=window_size, fill=0.0)
        self.output_buffer = List[Float64](length=window_size, fill=0.0)
        self.p = Print(world_ptr=self.world_ptr)

        @parameter
        if input_window_shape == WindowTypes.hann:
            self.input_attenuation_window = hann_window(window_size)
        elif input_window_shape == WindowTypes.hamming:
            self.input_attenuation_window = hamming_window(window_size)
        elif input_window_shape == WindowTypes.blackman:
            self.input_attenuation_window = blackman_window(window_size)
        elif input_window_shape == WindowTypes.sine:
            self.input_attenuation_window = sine_window(window_size)
        else:
            # never used, just allocate a bunch of zeros
            self.input_attenuation_window = List[Float64](length=window_size, fill=0.0)

        @parameter
        if output_window_shape == WindowTypes.hann:
            self.output_attenuation_window = hann_window(window_size)
        elif output_window_shape == WindowTypes.hamming:
            self.output_attenuation_window = hamming_window(window_size)
        elif output_window_shape == WindowTypes.blackman:
            self.output_attenuation_window = blackman_window(window_size)
        elif output_window_shape == WindowTypes.sine:
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
        if self.world_ptr[].top_of_block:
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

            @parameter
            if overlap_output:
                # @parameter
                for i in range(window_size):
                    self.output_buffer[(self.output_buffer_write_head + i) % window_size] += self.passing_buffer[i]
            else:
                # @parameter
                for i in range(window_size):
                    self.output_buffer[(self.output_buffer_write_head + i) % window_size] = self.passing_buffer[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.output_buffer[self.read_head]

        @parameter
        if overlap_output:
            self.output_buffer[self.read_head] = 0.0
        
        self.read_head = (self.read_head + 1) % window_size
        return outval

    fn next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, chan: Int = 0) -> Float64:
        """Process the next input sample and return the next output sample.
        
        This function is called in the audio processing loop for each input sample. It buffers the input samples,
        and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer.
            chan: The channel to read from the buffer.
        
        Returns:
            The next output sample.
        """
        
        if self.hop_counter == 0:
           
            @parameter
            if input_window_shape:
                for i in range(window_size):
                    index = floor(phase * buffer.get_num_frames()) + i
                    if index < buffer.get_num_frames():
                        self.passing_buffer[i] = buffer.read_index(chan, index) * self.input_attenuation_window[i]
                    else:
                        self.passing_buffer[i] = 0.0
            else:
                for i in range(window_size):
                    index = floor(phase * buffer.get_num_frames()) + i
                    if index < buffer.get_num_frames():
                        self.passing_buffer[i] = buffer.read_index(chan, index) * self.input_attenuation_window[i]
                    else:
                        self.passing_buffer[i] = 0.0

            self.process.next_window(self.passing_buffer)

            @parameter
            if output_window_shape:
                for i in range(window_size):
                    self.passing_buffer[i] *= self.output_attenuation_window[i]

            @parameter
            if overlap_output:
                for i in range(window_size):
                    self.output_buffer[(self.output_buffer_write_head + i) % window_size] += self.passing_buffer[i]
            else:
                for i in range(window_size):
                    self.output_buffer[(self.output_buffer_write_head + i) % window_size] = self.passing_buffer[i]

            self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
    
        self.hop_counter = (self.hop_counter + 1) % hop_size

        outval = self.output_buffer[self.read_head]

        @parameter
        if overlap_output:
            self.output_buffer[self.read_head] = 0.0
        
        self.read_head = (self.read_head + 1) % window_size
        return outval