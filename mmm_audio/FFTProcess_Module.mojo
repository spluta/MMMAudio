from mmm_audio import *

@doc_private
struct FFTProcessor[T: FFTProcessable, window_size: Int = 1024](BufferedProcessable):
    """This is a private struct that the user doesn't *need* to see or use. This is the
    connective tissue between FFTProcess (which the user *does* see and uses to
    create spectral processes) and BufferedProcess. To learn how this whole family of structs 
    works to create spectral processes, see the `FFTProcessable` trait.
    """
    var world: World
    var process: Self.T

    var fft: RealFFT[Self.window_size, 1]
    var fft2: RealFFT[Self.window_size, 2]
    var mags: List[Float64]
    var phases: List[Float64]
    var st_mags: List[SIMD[DType.float64,2]]
    var st_phases: List[SIMD[DType.float64,2]]

    @doc_private
    fn __init__(out self, world: World, var process: Self.T):
        self.world = world
        self.process = process^
        self.fft = RealFFT[Self.window_size, 1]()
        self.fft2 = RealFFT[Self.window_size, 2]()
        self.mags = List[Float64](length=(Self.window_size // 2) + 1, fill=0.0)
        self.phases = List[Float64](length=(Self.window_size // 2) + 1, fill=0.0)
        self.st_mags = List[SIMD[DType.float64,2]](length=(Self.window_size // 2 + 1 + 1) // 2, fill=SIMD[DType.float64,2](0.0))
        self.st_phases = List[SIMD[DType.float64,2]](length=(Self.window_size // 2 + 1 + 1) // 2, fill=SIMD[DType.float64,2](0.0))

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
    
    @doc_private
    fn send_streams(mut self) -> None:
        self.process.send_streams()

trait FFTProcessable(Movable,Copyable):
    """Implement this trait in a custom struct to pass to `FFTProcess`
    as a Parameter.

    See `TestFFTProcess.mojo` for an example on how to create a spectral process 
    using a struct that implements FFTProcessable.
    """
    fn next_frame(mut self, mut magnitudes: List[Float64], mut phases: List[Float64]) -> None:
        """This function is called when the internal buffered process has enough samples to 
        perform an FFT. The user can modify the magnitudes and phases in place to achieve 
        their desired spectral processing. The modified magnitudes and phases will then be 
        used by the internal buffered process to perform an IFFT and return to the time domain.

        This function has a default implementation that does nothing so it is possible to *not* 
        implement it. This would probably be because a stereo process is implementing 
        `next_stereo_frame()` instead.
        """
        return None
    fn next_stereo_frame(mut self, mut magnitudes: List[SIMD[DType.float64,2]], mut phases: List[SIMD[DType.float64,2]]) -> None:
        """The stereo version of `next_frame()`. See that for details.
        """
        return None
    fn get_messages(mut self) -> None:
        """This function is called at the top of each audio block to allow the user to retrieve any messages
        they may have sent to this process. Put your [Messenger](Messenger.md) message retrieval code here. (e.g. `self.messenger.update(self.param, "param_name")`).

        This method has a default implementation that does nothing, so it is not necessary to implement it if you don't need to retrieve any messages.
        """
        return None
    fn send_streams(mut self) -> None:
        """This function can be used to stream data back to Python. Put your [Messenger](Messenger.md) message sending code here.
        (e.g. `self.messenger.reply_stream("stream_name", value)`).

        This method has a default implementation that does nothing, so it is not necessary to implement it if you don't need to send any stream data.
        """
        return None

struct FFTProcess[T: FFTProcessable, window_size: Int = 1024, hop_size: Int = 512, input_window_shape: Int = WindowType.hann, output_window_shape: Int = WindowType.hann](Movable,Copyable):
    """Create an FFTProcess for audio manipulation in the frequency domain.

    Parameters:
        T: A user defined struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.
        window_size: The size of the FFT window.
        hop_size: The number of samples between each processed spectral frame.
        input_window_shape: Int specifying what window shape to use to modify the amplitude of the input samples before the FFT. See [WindowType](MMMWorld.md/#struct-windowtype) for the options.
        output_window_shape: Int specifying what window shape to use to modify the amplitude of the output samples after the IFFT. See [WindowType](MMMWorld.md/#struct-windowtype) for the options.
    """
    var world: World
    var buffered_process: BufferedProcess[FFTProcessor[Self.T, Self.window_size], Self.window_size, Self.hop_size, Self.input_window_shape, Self.output_window_shape]

    fn __init__(out self, world: World, var process: Self.T):
        """Initializes a `FFTProcess` struct.

        Args:
            world: A pointer to the MMMWorld.
            process: A user defined struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

        Returns:
            An initialized `FFTProcess` struct.
        """
        self.world = world
        self.buffered_process = BufferedProcess[FFTProcessor[Self.T, Self.window_size], Self.window_size, Self.hop_size, Self.input_window_shape, Self.output_window_shape](self.world, process=FFTProcessor[Self.T, Self.window_size](self.world, process=process^))

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
            input: The next input samples to process.
        
        Returns:
            The next output samples.
        """
        return self.buffered_process.next_stereo(input)

    fn next_from_buffer(mut self, ref buffer: Buffer, phase: Float64, chan: Int = 0) -> Float64:
        """Returns the next output sample from the internal buffered process. The buffered process reads a block of samples from the provided buffer at the given phase and channel on each hop.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer. Between 0 (beginning) and 1 (end).
            chan: The channel to read from the buffer.
        
        Returns:
            The next output sample.
        """
        return self.buffered_process.next_from_buffer(buffer, phase, chan)

    fn next_from_stereo_buffer(mut self, ref buffer: Buffer, phase: Float64, start_chan: Int = 0) -> SIMD[DType.float64, 2]:
        """Returns the next stereo output sample from the internal buffered process. The buffered process reads a block of samples from the provided buffer at the given phase and channel on each hop.

        Args:
            buffer: The input buffer to read samples from.
            phase: The current phase to read from the buffer. Between 0 (beginning) and 1 (end).
            start_chan: The first channel to read from the buffer.

        Returns:
            The next stereo output sample.
        """
        return self.buffered_process.next_from_stereo_buffer(buffer, phase, start_chan)

