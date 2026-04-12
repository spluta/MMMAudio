from mmm_audio import *

comptime iterations = 2

struct NessStretchWindow[num_iterations: Int=1](FFTProcessable):
    var world: World
    var window_size: Int
    var hop_size: Int
    var m: Messenger
    var lrhp_window: List[Float64]
    var lrlp_window: List[Float64]
    var previous_phases: List[MFloat[2]]
    var previous_mags: List[MFloat[2]]

    fn __init__(out self, world: World, window_size: Int, hop_size: Int, low_cut: Int, high_cut: Int):
        self.world = world
        self.window_size = window_size
        self.hop_size = hop_size
        self.m = Messenger(self.world)
        self.lrhp_window = create_lr_filter(self.window_size, low_cut, 24, highpass=True)
        self.lrlp_window = create_lr_filter(self.window_size, high_cut, 24, highpass=False)
        self.previous_phases = [MFloat[2](0.0, 0.0) for _ in range(self.window_size // 2 + 1)]
        self.previous_mags = [MFloat[2](0.0, 0.0) for _ in range(self.window_size // 2 + 1)]

    fn get_messages(mut self) -> None:
        pass

    fn next_stereo_frame(mut self, mut mags: List[MFloat[2]], mut phases: List[MFloat[2]]) -> None:
        fn call_back(mut phases: List[MFloat[2]]):
            for ref p in phases:
                p = MFloat[2](rrand(0.0, 2.0 * 3.141592653589793), rrand(0.0, 2.0 * 3.141592653589793))
        get_best_correlation[num_iterations=Self.num_iterations](mags, phases, self.previous_mags, self.previous_phases, self.window_size, self.hop_size, call_back)
        for i in range(len(mags)):
            mags[i] = mags[i] * self.lrlp_window[i]
            mags[i] = mags[i] * self.lrhp_window[i]

struct NessStretch(Movable, Copyable):
    var world: World
    var buffer: SIMDBuffer[2]
    var saw: LFSaw[1]
    var window_sizes: List[Int] 
    var hop_sizes: List[Int]

    var ness_stretches: List[FFTProcess[NessStretchWindow[num_iterations=iterations],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine]]

    var m: Messenger
    var dur_mult: Float64
    var file_name: String

    fn __init__(out self, world: World):
        self.world = world
        self.file_name = "resources/Shiverer.wav"
        self.buffer = SIMDBuffer.load("resources/Shiverer.wav")
        self.saw = LFSaw(self.world)
        self.window_sizes = [65536, 32768, 16384, 8192, 4096, 2048, 1024, 512, 256]
        self.hop_sizes = [32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128]

        start_cut = [0, 64, 64, 64, 64, 64, 64, 64, 64]

        # the upper register benefit from less correlation, so I am using fewer in the upper register.
        self.ness_stretches = [FFTProcess[
                NessStretchWindow[num_iterations=iterations],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[num_iterations=iterations](self.world, self.window_sizes[i], self.hop_sizes[i],start_cut[i], 128),window_size=self.window_sizes[i],hop_size=self.hop_sizes[i]) for i in range(0,9)]
  
        self.m = Messenger(self.world)
        self.dur_mult = 40.0

    fn next(mut self) -> SIMD[DType.float64,2]:
        self.m.update(self.dur_mult,"dur_mult")
        new_file = self.m.notify_update(self.file_name, "file_name")
        if new_file:
            self.buffer = SIMDBuffer.load(self.file_name)
        speed = 1.0/self.buffer.duration * (1.0/self.dur_mult)
        phase = self.saw.next(speed, trig = new_file)*0.5 + 0.5 #resets the phase when the file changes
        o = MFloat[2](0.0, 0.0)
        for ref n in self.ness_stretches:
            o += n.buffered_process.next_from_stereo_buffer[Interp.lagrange4](self.buffer, phase)
        # o += self.ness_stretches[1].buffered_process.next_from_stereo_buffer[Interp.lagrange4](self.buffer, phase)
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
        freq_bin: Current frequency bin index.
        cutoff_bin: Cutoff frequency bin index.
        order: Filter order (2=12dB/oct, 4=24dB/oct, 8=48dB/oct).
        highpass: If True, creates highpass; else lowpass.
    
    Returns:
        Filter magnitude coefficient for this bin.
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


