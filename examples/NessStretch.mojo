from mmm_audio import *

from random import random_float64

comptime window_sizes = [65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256]
comptime hop_sizes = [32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128]

struct NessStretchWindow[window_size: Int](FFTProcessable):
    var world: World
    var m: Messenger
    var lrhp_window: List[Float64]
    var lrlp_window: List[Float64]

    fn __init__(out self, world: World, low_cut: Int, high_cut: Int):
        self.world = world
        self.m = Messenger(self.world)
        self.lrhp_window = create_lr_filter(Self.window_size, low_cut, 24, highpass=True)
        self.lrlp_window = create_lr_filter(Self.window_size, high_cut, 24, highpass=False)

    fn get_messages(mut self) -> None:
        pass

    fn next_stereo_frame(mut self, mut mags: List[MFloat[2]], mut phases: List[MFloat[2]]) -> None:
        for ref p in phases:
            p = MFloat[2](random_float64(0.0, 2.0 * 3.141592653589793), random_float64(0.0, 2.0 * 3.141592653589793))
        for i in range(len(mags)):
            mags[i] = mags[i] * self.lrlp_window[i]
            mags[i] = mags[i] * self.lrhp_window[i]

# User's Synth
struct NessStretch(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var saw: LFSaw[1]
    var ness_stretches: Tuple[
        FFTProcess[NessStretchWindow[window_sizes[0]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[1]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[2]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[3]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[4]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[5]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[6]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[7]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine],
        FFTProcess[NessStretchWindow[window_sizes[8]],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine]
    ]
    var m: Messenger
    var dur_mult: Float64
    var file_name: String

    fn __init__(out self, world: World):
        self.world = world
        self.file_name = "resources/Shiverer.wav"
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.saw = LFSaw(self.world)

        self.ness_stretches = (FFTProcess[
                NessStretchWindow[window_sizes[0]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[0]](self.world, 0, 128),window_size=materialize[window_sizes[0]](),hop_size=materialize[hop_sizes[0]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[1]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[1]](self.world, 64, 128),window_size=materialize[window_sizes[1]](),hop_size=materialize[hop_sizes[1]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[2]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[2]](self.world, 64, 128),window_size=materialize[window_sizes[2]](),hop_size=materialize[hop_sizes[2]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[3]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[3]](self.world, 64, 128),window_size=materialize[window_sizes[3]](),hop_size=materialize[hop_sizes[3]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[4]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[4]](self.world, 64, 128),window_size=materialize[window_sizes[4]](),hop_size=materialize[hop_sizes[4]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[5]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[5]](self.world, 64, 128),window_size=materialize[window_sizes[5]](),hop_size=materialize[hop_sizes[5]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[6]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[6]](self.world, 64, 128),window_size=materialize[window_sizes[6]](),hop_size=materialize[hop_sizes[6]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[7]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[7]](self.world, 64, 128),window_size=materialize[window_sizes[7]](),hop_size=materialize[hop_sizes[7]]()),
            FFTProcess[
                NessStretchWindow[window_sizes[8]],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[window_sizes[8]](self.world, 64, 128),window_size=materialize[window_sizes[8]](),hop_size=materialize[hop_sizes[8]]())
        )

        self.m = Messenger(self.world)
        self.dur_mult = 40.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        new_file = self.m.notify_update(self.file_name, "file_name")
        if new_file:
            self.buffer = Buffer.load(self.file_name)
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        phase = self.saw.next(speed)*0.5 + 0.5
        o = self.ness_stretches[0].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[1].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[2].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[3].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[4].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[5].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[6].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[7].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        o += self.ness_stretches[8].buffered_process.next_from_stereo_buffer(self.buffer, phase, 0)
        return o

fn linkwitz_riley_bin(
    freq_bin: Int,
    cutoff_bin: Int,
    order: Int,
    highpass: Bool = False
) -> Float64:
    """
    Calculate Linkwitz-Riley filter response for a single bin.
    
    Args:
        freq_bin: Current frequency bin index
        cutoff_bin: Cutoff frequency bin index
        order: Filter order (2=12dB/oct, 4=24dB/oct, 8=48dB/oct)
        highpass: If True, creates highpass; else lowpass
    
    Returns:
        Filter magnitude coefficient for this bin
    """
    if cutoff_bin == 0:
        return 1.0
    
    var ratio = Float64(freq_bin) / Float64(cutoff_bin)
    
    # Butterworth squared = Linkwitz-Riley
    # LR is two cascaded Butterworth filters
    var butterworth_order = order // 2
    var omega_ratio_pow = pow(ratio, Float64(butterworth_order * 2))
    
    # Butterworth magnitude squared
    var butterworth_mag_sq = 1.0 / (1.0 + omega_ratio_pow)
    
    # Linkwitz-Riley is Butterworth squared
    var lr_response = butterworth_mag_sq
    
    if highpass:
        lr_response = 1.0 - lr_response
    
    return sqrt(lr_response)


fn create_lr_filter(
    fft_size: Int,
    cutoff_bin: Int,
    slope_db_per_octave: Int,
    highpass: Bool = False
) -> List[Float64]:
    """
    Create a Linkwitz-Riley frequency domain filter.
    
    Args:
        fft_size: Size of the FFT.
        cutoff_bin: Cutoff frequency as bin index.
        slope_db_per_octave: Filter slope (12, 24, 36, 48 dB/octave).
        highpass: If True, creates highpass; else lowpass.
    
    Returns:
        List of magnitude coefficients for positive frequencies.
    """
    # Convert slope to order: 12dB/oct = 2nd order, 24dB/oct = 4th order, etc.
    var order = slope_db_per_octave // 6
    
    var num_bins = fft_size // 2 + 1
    var filter_response = List[Float64](capacity=num_bins)
    
    for i in range(num_bins):
        var magnitude = linkwitz_riley_bin(i, cutoff_bin, order, highpass)
        filter_response.append(magnitude)
    
    return filter_response^


