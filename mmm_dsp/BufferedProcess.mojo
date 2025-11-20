from mmm_src.MMMWorld import *
from mmm_utils.Windows import *
from math import floor

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
    fn get_messages(mut self) -> None:
        return None

struct BufferedInput[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Optional[Int] = None](Movable, Copyable):
    """Buffers input samples and hands them over to be processed in 'windows'.
    
    BufferedProcess struct handles buffering of input samples and handing them as "windows" 
    to a user defined struct for processing (The user defined struct must implement the 
    BufferedProcessable trait). The user defined struct's `next_window()` function is called every
    `hop_size` samples. BufferedProcess passes the user defined struct a List of `window_size` samples. 
    The user can process can do whatever they want with the samples (probably some kind of 
    windowed analysis). BufferedInput does not return any output samples, it is intended
    for analysis purposes only.

    Parameters:
        T: A user defined struct that implements the BufferedProcessable trait.
        window_size: The size of the window that is passed to the user defined struct for processing. The default is 1024 samples.
        hop_size: The number of samples between each call to the user defined struct's `next_window()` function. The default is 512 samples.
        input_window_shape: Optional window shape to apply to the input samples before passing them to the user defined struct. Use alias variables from WindowTypes struct (e.g. WindowTypes.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var input_buffer: List[Float64]
    var passing_buffer: List[Float64]
    var write_head: Int
    var process: T
    var hop_counter: Int
    var input_attenuation_window: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], var process: T):
        self.world_ptr = world_ptr
        self.input_buffer = List[Float64](length=window_size * 2, fill=0.0)
        self.passing_buffer = List[Float64](length=window_size, fill=0.0)
        self.write_head = 0
        self.hop_counter = 0
        self.process = process^
        self.input_attenuation_window = get_window_type(input_window_shape, window_size)
    
    fn write_sample(mut self, input: Float64) -> None:
        self.input_buffer[self.write_head] = input
        self.input_buffer[self.write_head + window_size] = input
        self.write_head = (self.write_head + 1) % window_size

    fn fill_passing_buffer(mut self) -> None:
        @parameter
        if input_window_shape:
            # @parameter
            for i in range(window_size):
                self.passing_buffer[i] = self.input_buffer[self.write_head + i] * self.input_attenuation_window[i]
        else:
            # @parameter
            for i in range(window_size):
                self.passing_buffer[i] = self.input_buffer[self.write_head + i]

    fn next(mut self, input: Float64) -> None:
        self.write_sample(input)
        if self.hop_counter == 0:
            self.fill_passing_buffer()
            self.process.next_window(self.passing_buffer)
        
        self.hop_counter = (self.hop_counter + 1) % hop_size


struct BufferedProcess[T: BufferedProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Optional[Int] = None, output_window_shape: Optional[Int] = None,overlap_output: Bool = True](Movable, Copyable):
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
        input_window_shape: Optional window shape to apply to the input samples before passing them to the user defined struct. Use alias variables from WindowTypes struct (e.g. WindowTypes.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
        output_window_shape: Optional window shape to apply to the output samples after processing by the user defined struct. Use alias variables from WindowTypes struct (e.g. WindowTypes.hann) found in mmm_utils.Windows. If None, no window is applied. The default is None.
        overlap_output: If True, overlapping output samples (because hop_size < window_size) are summed together. If False, overlapping output samples overwrite previous samples. This would be useful to set to False if the user defined processing is doing something like pitch analysis and replacing all the values in the received List with the detected pitch value. In this case, summing would not make sense (neither would windowing the output) because it would be doing math on the pitch values that you want to just stay as they are. The default is True.
    """
    var world_ptr: UnsafePointer[MMMWorld]
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

        self.st_input_buffer = List[SIMD[DType.float64,2]](length=window_size * 2, fill=0.0)
        self.st_passing_buffer = List[SIMD[DType.float64,2]](length=window_size, fill=0.0)
        self.st_output_buffer = List[SIMD[DType.float64,2]](length=window_size, fill=0.0)

        self.p = Print(world_ptr=self.world_ptr)

        self.input_attenuation_window = get_window_type(input_window_shape, window_size)
        self.output_attenuation_window = get_window_type(output_window_shape, window_size)

    fn next[num_chans: Int = 1](mut self, input: SIMD[DType.float64, num_chans]) -> SIMD[DType.float64, num_chans]:
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
    
        @parameter
        if num_chans == 1:
            self.input_buffer[self.input_buffer_write_head] = input[0]
            self.input_buffer[self.input_buffer_write_head + window_size] = input[0]
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

            var outval = self.output_buffer[self.read_head]

            @parameter
            if overlap_output:
                self.output_buffer[self.read_head] = 0.0
            
            self.read_head = (self.read_head + 1) % window_size
            return outval

        elif num_chans == 2:
            self.st_input_buffer[self.input_buffer_write_head] = SIMD[DType.float64,2](input[0], input[1])
            self.st_input_buffer[self.input_buffer_write_head + window_size] = SIMD[DType.float64,2](input[0], input[1])
            self.input_buffer_write_head = (self.input_buffer_write_head + 1) % window_size
            
            if self.hop_counter == 0:

                @parameter
                if input_window_shape:
                    # @parameter # for some reason these slow compilation down a lot
                    for i in range(window_size):
                        self.st_passing_buffer[i] = self.st_input_buffer[self.input_buffer_write_head + i] * SIMD[DType.float64,2](self.input_attenuation_window[i], self.input_attenuation_window[i])
                else:
                    # @parameter
                    for i in range(window_size):
                        self.st_passing_buffer[i] = self.st_input_buffer[self.input_buffer_write_head + i]

                self.process.next_window[2](self.st_passing_buffer)

                @parameter
                if output_window_shape:
                    # @parameter
                    for i in range(window_size):
                        self.st_passing_buffer[i] *= SIMD[DType.float64,2](self.output_attenuation_window[i], self.output_attenuation_window[i])

                @parameter
                if overlap_output:
                    # @parameter
                    for i in range(window_size):
                        self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] += self.st_passing_buffer[i]
                else:
                    # @parameter
                    for i in range(window_size):
                        self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] = self.st_passing_buffer[i]

                self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
        
            self.hop_counter = (self.hop_counter + 1) % hop_size

            var outval = self.st_output_buffer[self.read_head]

            @parameter
            if overlap_output:
                self.st_output_buffer[self.read_head] = 0.0
            
            self.read_head = (self.read_head + 1) % window_size
            return SIMD[DType.float64, num_chans](outval[0], outval[1])

        else:
            return SIMD[DType.float64, num_chans](0.0)

    fn next_from_buffer[num_chans: Int = 1](mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> SIMD[DType.float64, num_chans]:
        """Process the next input sample and return the next output sample.
        
        This function is called in the audio processing loop for each input sample. It buffers the input samples,
        and internally here calls the user defined struct's `.next_window()` method every `hop_size` samples.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer.
            start_chan: The firstchannel to read from the buffer.
        
        Returns:
            The next output sample.
        """
        
        @parameter
        if num_chans == 1:
            if self.hop_counter == 0:
                
                @parameter
                if input_window_shape:
                    for i in range(window_size):
                        index = floor(phase * buffer.get_num_frames()) + i
                        if index < buffer.get_num_frames() and index >= 0:
                            self.passing_buffer[i] = buffer.read_index(start_chan, index) * self.input_attenuation_window[i]
                        else:
                            self.passing_buffer[i] = 0.0
                else:
                    for i in range(window_size):
                        index = floor(phase * buffer.get_num_frames()) + i
                        if index < buffer.get_num_frames() and index >= 0:
                            self.passing_buffer[i] = buffer.read_index(start_chan, index) * self.input_attenuation_window[i]
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
        elif num_chans == 2:
            if self.hop_counter == 0:
                @parameter
                if input_window_shape:
                    for i in range(window_size):
                        index = floor(phase * buffer.get_num_frames()) + i
                        if index < buffer.get_num_frames() and index >= 0:
                            self.st_passing_buffer[i] = buffer.read_index[2](start_chan, index) * self.input_attenuation_window[i]
                        else:
                            self.st_passing_buffer[i] = 0.0
                else:
                    for i in range(window_size):
                        index = floor(phase * buffer.get_num_frames()) + i
                        if index < buffer.get_num_frames() and index >= 0:
                            self.st_passing_buffer[i] = buffer.read_index[2](start_chan, index) * self.input_attenuation_window[i]
                        else:
                            self.st_passing_buffer[i] = 0.0

                self.process.next_window[2](self.st_passing_buffer)

                @parameter
                if output_window_shape:
                    for i in range(window_size):
                        self.st_passing_buffer[i] *= self.output_attenuation_window[i]
                @parameter
                if overlap_output:
                    for i in range(window_size):
                        self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] += self.st_passing_buffer[i]
                else:
                    for i in range(window_size):
                        self.st_output_buffer[(self.output_buffer_write_head + i) % window_size] = self.st_passing_buffer[i]

                self.output_buffer_write_head = (self.output_buffer_write_head + hop_size) % window_size
        
            self.hop_counter = (self.hop_counter + 1) % hop_size

            var outval = self.st_output_buffer[self.read_head]

            @parameter
            if overlap_output:
                self.st_output_buffer[self.read_head] = 0.0
            
            self.read_head = (self.read_head + 1) % window_size
            return SIMD[DType.float64, num_chans](outval[0], outval[1])

        else:
            return SIMD[DType.float64, num_chans](0.0)