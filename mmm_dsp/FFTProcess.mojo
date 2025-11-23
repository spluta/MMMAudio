from mmm_dsp.BufferedProcess import *
from mmm_dsp.FFT import *
from mmm_dsp.Buffer import Buffer

@doc_private
struct FFTProcessor[T: FFTProcessable, window_size: Int = 1024](BufferedProcessable):
    """This is a private struct that the user doesn't *need* to see. This is the
    connective tissue between SpectralProcess (which the user *does* see and uses to
    create spectral processes) and BufferedProcess. To learn how this whole family of structs 
    works to create spectral processes, see the `SpectralProcessable` trait.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var process: T

    # this is a bit gross. In order to get this to work the FFT has to have the data structure of both single channel FFT and a two channel FFT.
    # once Mojo allows parameters and traits. We should get rid of this as soon as possible.
    var fft: RealFFT[window_size, 1]
    var fft2: RealFFT[window_size, 2]
    var mags: List[Float64]
    var phases: List[Float64]
    var st_mags: List[SIMD[DType.float64,2]]
    var st_phases: List[SIMD[DType.float64,2]]

    @doc_private
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], var process: T):
        self.world_ptr = world_ptr
        self.process = process^
        self.fft = RealFFT[window_size, 1]()
        self.fft2 = RealFFT[window_size, 2]()
        self.mags = List[Float64](length=(window_size // 2) + 1, fill=0.0)
        self.phases = List[Float64](length=(window_size // 2) + 1, fill=0.0)
        self.st_mags = List[SIMD[DType.float64,2]](length=(window_size // 2 + 1 + 1) // 2, fill=SIMD[DType.float64,2](0.0))
        self.st_phases = List[SIMD[DType.float64,2]](length=(window_size // 2 + 1 + 1) // 2, fill=SIMD[DType.float64,2](0.0))

    fn next_window(mut self, mut input: List[Float64]) -> None:
        self.fft.fft(input)
        self.process.next_frame(self.fft.mags,self.fft.phases)
        self.fft.ifft(input)
    
    fn next_stereo_window(mut self, mut input: List[SIMD[DType.float64,2]]) -> None:
        self.fft2.fft(input)
        self.process.next_stereo_frame(self.fft2.mags,self.fft2.phases)
        self.fft2.ifft(input)

    @doc_private
    fn get_messages(mut self) -> None:
        self.process.get_messages()

trait FFTProcessable(Movable,Copyable):
    """Implement this trait in a custom struct to pass to `FFTProcess`
    as a Parameter.

    See `TestSpectralProcess.mojo` for an example on how to create a spectral process 
    using a struct that implements SpectralProcessable.

    This trait requires that two functions be implemented (see below for more details).

    * `fn next_spectral_frame()`: This function gets passed a list of magnitudes
    and a list of phases that are the result of an FFT. The user should manipulate 
    these values in place so that once this function is done the values in those 
    lists are what the user wants to be used for the IFFT conversion back into 
    amplitude samples. Because the FFT only happens every `hop_size` samples (and
    uses the most recent `window_size` samples), this function only gets called every
    `hop_size` samples. `hop_size` is set as a parameter in the `FFTProcessor`
    struct that the user's struct is passed to.
    * `fn get_messages()`: Because `.next_frame()` only runs every `hop_size`
    samples and a `Messenger` can only check for new messages from Python at the top 
    of every audio block, it's not guaranteed that these will line up, so this struct
    could very well miss incoming messages! To remedy this, put all your message getting
    code in this get_messages() function. It will get called by FFTProcessor (whose 
    `.next()` function does get called every sample) to make sure that any messages
    intended for this struct get updated.

    ## Outline of Spectral Processing:

    1. The user creates a custom struct that implements the SpectralProcessable trait. The
    required functions for that are `.next_frame()` and `.get_messages()`. 
    `.next_spectral_frame()` is passed a `List[Float64]` of magnitudes and a
    `List[Float64]` of phases. The user can manipulate this data however they want and 
    then needs to replace the values in those lists with what they want to be used for
    the IFFT.
    2. The user passes their struct (in 1) as a Parameter to the `SpectralProcess` struct. 
    You can see where the parameters such as `window_size`, `hop_size`, and window types 
    are expressed.
    3. In the user synth's `.next()` function (running one sample at a time) they pass in
    every sample to the `SpectralProcess`'s `.next()` function which:
        * has a `BufferedProcess` to store samples and pass them on 
        to `FFTProcessor` when appropriate
        * when `FFTProcessor` receives a window of amplitude samples, it performs an
        `FFT` getting the mags and phases which are then passed on to the user's 
        struct that implements `SpectralProcessable`. The mags and phases are modified in place
        and then this whole pipeline basically hands the data all the way back out to the user's
        synth struct where `SpectralProcess`'s `.next()` function returns the next appropriate
        sample (after buffering -> FFT -> processing -> IFFT -> output buffering) to get out 
        to the speakers (or whatever).
    """
    fn next_frame(mut self, mut magnitudes: List[Float64], mut phases: List[Float64]) -> None:
        return None
    fn next_stereo_frame(mut self, mut magnitudes: List[SIMD[DType.float64,2]], mut phases: List[SIMD[DType.float64,2]]) -> None:
        return None
    fn get_messages(mut self) -> None:
        return None

struct FFTProcess[T: FFTProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Optional[Int] = None, output_window_shape: Optional[Int] = None, overlap_output: Bool = True](Movable,Copyable):
    """Create an FFTProcess for audio manipulation in the frequency domain.
    
    SpectralProcess is similar to BufferedProcess, but instead of passing time domain samples to the user defined struct,
    it passes frequency domain magnitudes and phases (obtained from an FFT). The user defined struct must implement
    the SpectralProcessable trait, which requires the implementation of the `.next_frame()` function. This function
    receives two Lists: one for magnitudes and one for phases. The user can do whatever they want with the values in these Lists,
    and then must replace the values in the Lists with the values they want to be used for the IFFT to convert the information
    back to amplitude samples.

    Parameters:
        T: A user defined struct that implements the SpectralProcessable trait.
        window_size: The size of the FFT window. The default is 1024 samples.
        hop_size: The number of samples between each processed spectral frame. The default is 512.
        input_window_shape: An Optional[Int] specifying what window shape to use to modify the amplitude of the input samples before the FFT. See mmm_utils.Windows -> WindowTypes for the options.
        output_window_shape: An Optional[Int] specifying what window shape to use to modify the amplitude of the output samples after the IFFT. See mmm_utils.Windows -> WindowTypes for the options.
        overlap_output: If True, overlapping output samples after the IFFT (because hop_size < window_size) are summed together. If False, overlapping output samples overwrite previous samples. I'm not sure if this is useful for the `SpectralProcess` struct, but it's here for consistency with `BufferedProcess`.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var buffered_process: BufferedProcess[FFTProcessor[T, window_size], window_size, hop_size, input_window_shape, output_window_shape, overlap_output]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], var process: T):
        """Initializes a SpectralProcess struct.

        Args:
            world_ptr: A pointer to the MMMWorld.
            process: A user defined struct that implements the SpectralProcessable trait.

        Returns:
            An initialized SpectralProcess struct.
        """
        self.world_ptr = world_ptr
        self.buffered_process = BufferedProcess[FFTProcessor[T, window_size], window_size, hop_size,input_window_shape, output_window_shape, overlap_output](self.world_ptr, process=FFTProcessor[T, window_size](self.world_ptr, process=process^))

    fn next(mut self, input: Float64) -> Float64:
        """Processes the next input sample and returns the next output sample.
        
        Args:
            input: The next input sample to process.
        
        Returns:
            The next output sample.
        """
        return self.buffered_process.next(input)

    fn next_stereo(mut self, input: SIMD[DType.float64, 2]) -> SIMD[DType.float64, 2]:
        """Processes the next stereo input sample and returns the next output sample.
        
        Args:
            input: The next input sample to process.
        
        Returns:
            The next output sample.
        """
        return self.buffered_process.next_stereo(input)

    fn next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> Float64:
        """Returns the next output sample from the internal buffered process. The buffered process reads a block of samples from the provided buffer at the given phase and channel on each hop.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer.
            start_chan: The firstchannel to read from the buffer.
        
        Returns:
            The next output sample from the internal buffer.
        """
        return self.buffered_process.next_from_buffer(buffer, phase, start_chan)

    fn next_from_stereo_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> SIMD[DType.float64, 2]:
        """Returns the next stereo output sample from the internal buffered process. The buffered process reads a block of samples from the provided buffer at the given phase and channel on each hop.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer.
            start_chan: The firstchannel to read from the buffer.

        Returns:
            The next stereo output sample from the internal buffer.
        """
        return self.buffered_process.next_from_stereo_buffer(buffer, phase, start_chan)