from mmm_audio import *

fn wrap_to_pi[num_chans: Int](phase: MFloat[num_chans]) -> MFloat[num_chans]:
    return atan2(sin(phase), cos(phase))
    
fn phase_difference_bin[num_chans: Int](current_phase: MFloat[num_chans], previous_phase: MFloat[num_chans], 
                        bin_num: Int, hop_size: Int, fft_size: Int) -> MFloat[num_chans]:
    expected_shift = two_pi * Float64(bin_num * hop_size) / Float64(fft_size)
    delta_phase = current_phase - previous_phase - expected_shift
    
    return wrap_to_pi(delta_phase)

fn phase_correlation[num_chans: Int](current_phases: Span[MFloat[num_chans]], previous_phases: Span[MFloat[num_chans]], 
                     hop_size: Int, fft_size: Int) -> MFloat[num_chans]:
    """Returns [-1, 1]. 1 = in-phase, -1 = inverted, 0 = uncorrelated."""
    var num_bins = len(current_phases)
    var sum_cos = MFloat[num_chans](0.0)
    
    for i in range(num_bins):
        var delta = phase_difference_bin(current_phases[i], previous_phases[i], 
                                         i, hop_size, fft_size)
        sum_cos += cos(delta)
    
    var n = MFloat[num_chans](Float64(num_bins))
    return sum_cos / n

fn get_best_correlation[num_chans: Int, num_iterations: Int](mut phases: List[MFloat[num_chans]], mut previous_phases: List[MFloat[num_chans]], window_size: Int, hop_size: Int, call_back: fn (mut phases: List[MFloat[num_chans]])):
    """Calls a callback function `num_iterations` times, and keeps the phase set with the best correlation to the previous phases. The callback function should modify the `phases` variable in place."""

    phase_corr = MFloat[num_chans](-1.0)
    @parameter
    if num_iterations < 1:
        call_back(phases)
    else:
        @parameter
        for i in range(num_iterations):
            call_back(phases)
            phase_corr_new = phase_correlation(phases, previous_phases, hop_size, window_size)

            lt0 = phase_corr_new.lt(0.0)
            phase_corr_new = abs(phase_corr_new)
            gt_last = phase_corr_new.gt(phase_corr)

            # if the absolute value of the new correlation is higher than the last one, we want to keep it, but if the correlation is negative, we want to invert the phases
            # otherwise we want to keep the old phases. 
            for i2 in range(len(phases)):
                phases[i2] = gt_last.select(lt0.select(wrap_to_pi(phases[i2] + pi), phases[i2]), previous_phases[i2])

            phase_corr = phase_corr_new

    previous_phases = phases.copy()


comptime onsies_iterations = 1
comptime twosies_iterations = 2

struct NessStretchWindow[num_iterations: Int=1](FFTProcessable):
    var world: World
    var window_size: Int
    var hop_size: Int
    var m: Messenger
    var lrhp_window: List[Float64]
    var lrlp_window: List[Float64]
    var previous_phases: List[MFloat[2]]
    var temp_phases: List[MFloat[2]]

    fn __init__(out self, world: World, window_size: Int, hop_size: Int, low_cut: Int, high_cut: Int):
        self.world = world
        self.window_size = window_size
        self.hop_size = hop_size
        self.m = Messenger(self.world)
        self.lrhp_window = create_lr_filter(self.window_size, low_cut, 24, highpass=True)
        self.lrlp_window = create_lr_filter(self.window_size, high_cut, 24, highpass=False)
        self.previous_phases = [MFloat[2](0.0, 0.0) for _ in range(self.window_size // 2 + 1)]
        self.temp_phases = [MFloat[2](0.0, 0.0) for _ in range(self.window_size // 2 + 1)]

    fn get_messages(mut self) -> None:
        pass

    fn next_stereo_frame(mut self, mut mags: List[MFloat[2]], mut phases: List[MFloat[2]]) -> None:
        fn call_back(mut phases: List[MFloat[2]]):
            for ref p in phases:
                p = MFloat[2](rrand(0.0, 2.0 * 3.141592653589793), rrand(0.0, 2.0 * 3.141592653589793))
        get_best_correlation[num_iterations=Self.num_iterations](phases, self.previous_phases, self.window_size, self.hop_size, call_back)
        for i in range(len(mags)):
            mags[i] = mags[i] * self.lrlp_window[i]
            mags[i] = mags[i] * self.lrhp_window[i]

# User's Synth
struct NessStretch(Movable, Copyable):
    var world: World
    var buffer: SIMDBuffer[2]
    var saw: LFSaw[1]
    var window_sizes: List[Int] 
    var hop_sizes: List[Int]

    var ness_stretch_twosies: List[FFTProcess[NessStretchWindow[num_iterations=twosies_iterations],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine]]
    var ness_stretch_onesies: List[FFTProcess[NessStretchWindow[num_iterations=onsies_iterations],ifft=True,input_window_shape=WindowType.sine,output_window_shape=WindowType.sine]]

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
        self.ness_stretch_twosies = [FFTProcess[
                NessStretchWindow[num_iterations=twosies_iterations],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[num_iterations=twosies_iterations](self.world, self.window_sizes[i], self.hop_sizes[i],start_cut[i], 128),window_size=self.window_sizes[i],hop_size=self.hop_sizes[i]) for i in range(0,5)]
        self.ness_stretch_onesies = [FFTProcess[
                NessStretchWindow[num_iterations=onsies_iterations],
                ifft=True,
                input_window_shape=WindowType.sine,
                output_window_shape=WindowType.sine,
                
            ](self.world,process=NessStretchWindow[num_iterations=onsies_iterations](self.world, self.window_sizes[i], self.hop_sizes[i],start_cut[i], 128),window_size=self.window_sizes[i],hop_size=self.hop_sizes[i]) for i in range(5,9)]
            
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
        for ref n in self.ness_stretch_twosies:
            o += n.buffered_process.next_from_stereo_buffer[Interp.lagrange4](self.buffer, phase)
        for ref n in self.ness_stretch_onesies:
            o += n.buffered_process.next_from_stereo_buffer[Interp.lagrange4](self.buffer, phase)
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


