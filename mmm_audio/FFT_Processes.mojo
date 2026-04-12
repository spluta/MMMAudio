from mmm_audio import *

struct HilbertWindow(ComplexFFTProcessable):
    var m: Messenger
    var radians: Float64
    var window_size: Int

    fn __init__(out self, world: World, window_size: Int):
        self.m = Messenger(world)
        self.radians = pi_over2
        self.window_size = window_size

    fn get_messages(mut self) -> None:
        pass

    fn next_frame(mut self, mut complex: List[ComplexSIMD[DType.float64, 1]]) -> None:
        complex[0] *= ComplexSIMD[DType.float64, 1](0.0, 0.0)
        complex[self.window_size] *= ComplexSIMD[DType.float64, 1](0.0, 0.0)

        for i in range(1, self.window_size):
            complex[i] *= ComplexSIMD[DType.float64, 1](math.cos(self.radians), math.sin(self.radians))

struct Hilbert[window_type: Int = WindowType.sine](Movable, Copyable):
    var world: World
    var hilbert: ComplexFFTProcess[HilbertWindow,True,Self.window_type,Self.window_type]
    var window_size: Int
    var hop_size: Int
    var delay: Delay[1, Interp.none]
    var delay_time: MFloat[]

    fn __init__(out self, window_size: Int, hop_size: Int, world: World):
        self.world = world
        self.window_size = window_size
        self.hop_size = hop_size
        self.delay_time = Float64(self.window_size)/self.world[].sample_rate

        self.delay = Delay[1, Interp.none](self.world, Int(self.window_size))

        self.hilbert = ComplexFFTProcess[
                HilbertWindow,
                True,
                Self.window_type,
                Self.window_type
            ](self.world,HilbertWindow(self.world, self.window_size), self.window_size, self.hop_size)

    fn next(mut self, input: MFloat[1], radians: Float64) -> Tuple[Float64, Float64]:
        """Process one sample through the Hilbert transform, returning the delayed input sample and the Hilbert transform output sample.
        
        Args:
            input: The input sample to process.
            radians: The angle in radians to rotate the Hilbert transform output by.
        """
        self.hilbert.buffered_process.process.process.radians = radians
        o = self.hilbert.next(input)
        delayed: Float64 = self.delay.next(input, MInt[1](self.window_size))
        return Tuple(delayed, o)


fn wrap_to_pi[num_chans: Int](phase: MFloat[num_chans]) -> MFloat[num_chans]:
    return atan2(sin(phase), cos(phase))
    
fn phase_difference_bin[num_chans: Int](current_phase: MFloat[num_chans], previous_phase: MFloat[num_chans], 
                        bin_num: Int, hop_size: Int, fft_size: Int) -> MFloat[num_chans]:
    expected_shift = two_pi * Float64(bin_num * hop_size) / Float64(fft_size)
    delta_phase = current_phase - previous_phase - expected_shift
    
    return wrap_to_pi(delta_phase)

fn phase_correlation[num_chans: Int](
    current_phases: Span[MFloat[num_chans]], 
    previous_phases: Span[MFloat[num_chans]], 
    current_mags: Span[MFloat[num_chans]],
    previous_mags: Span[MFloat[num_chans]],
    hop_size: Int, fft_size: Int
) -> MFloat[num_chans]:
    var num_bins = len(current_phases)
    var sum_cos = MFloat[num_chans](0.0)
    var weight_sum = MFloat[num_chans](0.0)
    
    for i in range(num_bins):
        var delta = phase_difference_bin(current_phases[i], previous_phases[i], 
                                         i, hop_size, fft_size)
        
        var weight = current_mags[i] * previous_mags[i]
        sum_cos += weight * cos(delta)
        weight_sum += weight
    
    return sum_cos / (weight_sum + 1e-9)

fn get_best_correlation[num_chans: Int, num_iterations: Int](mut mags: List[MFloat[num_chans]], mut phases: List[MFloat[num_chans]], mut previous_mags: List[MFloat[num_chans]], mut previous_phases: List[MFloat[num_chans]], window_size: Int, hop_size: Int, call_back: fn (mut mags: List[MFloat[num_chans]], mut phases: List[MFloat[num_chans]])):
    """Calls a callback function `num_iterations` times, and keeps the mag/phase set with the best correlation to the previous phases. There are two versions of this function, one that allows the callback to modify both mags and phases, and one that only allows the callback to modify just the phases.
    
    Args:
        mags: The magnitudes of the current frame, which can be modified by the callback function.
        phases: The phases of the current frame, which can be modified by the callback function.
        previous_mags: The magnitudes of the previous frame, which are used to calculate the correlation.
        previous_phases: The phases of the previous frame, which are used to calculate the correlation.
        window_size: The size of the FFT window, used to calculate the expected phase shift.
        hop_size: The hop size of the FFT, used to calculate the expected phase shift.
        call_back: A function that takes the mags and phases or just the phases as arguments and modifies them in place.
    """

    phase_corr = MFloat[num_chans](-1.0)
    call_back(mags, phases)
    @parameter
    if num_iterations > 0:
        @parameter
        for i in range(num_iterations):
            temp_phases = phases.copy()
            temp_mags = mags.copy()
            @parameter
            if i > 0:
                call_back(mags, phases)
            phase_corr_new = phase_correlation(phases, previous_phases, mags, previous_mags, hop_size, window_size)

            lt0 = phase_corr_new.lt(0.0)
            phase_corr_new = abs(phase_corr_new)
            gt_last = phase_corr_new.gt(phase_corr)

            # if the absolute value of the new correlation is higher than the last one, we want to keep it, but if the correlation is negative, we want to invert the phases
            # otherwise we want to keep the old phases. 
            for i2 in range(len(phases)):
                phases[i2] = gt_last.select(lt0.select(wrap_to_pi(phases[i2] + pi), phases[i2]), temp_phases[i2])
                mags[i2] = gt_last.select(mags[i2], temp_mags[i2])

            phase_corr = phase_corr_new
    previous_phases = phases.copy()
    previous_mags = mags.copy()

fn get_best_correlation[num_chans: Int, num_iterations: Int](mut mags: List[MFloat[num_chans]], mut phases: List[MFloat[num_chans]], mut previous_mags: List[MFloat[num_chans]], mut previous_phases: List[MFloat[num_chans]], window_size: Int, hop_size: Int, call_back: fn (mut phases: List[MFloat[num_chans]])):
    """Calls a callback function `num_iterations` times, and keeps the mag/phase set with the best correlation to the previous phases. There are two versions of this function, one that allows the callback to modify both mags and phases, and one that only allows the callback to modify just the phases.
    
    Args:
        mags: The magnitudes of the current frame, which can be modified by the callback function.
        phases: The phases of the current frame, which can be modified by the callback function.
        previous_mags: The magnitudes of the previous frame, which are used to calculate the correlation.
        previous_phases: The phases of the previous frame, which are used to calculate the correlation.
        window_size: The size of the FFT window, used to calculate the expected phase shift.
        hop_size: The hop size of the FFT, used to calculate the expected phase shift.
        call_back: A function that takes the mags and phases or just the phases as arguments and modifies them in place.
    """

    phase_corr = MFloat[num_chans](-1.0)
    call_back(phases)
    @parameter
    if num_iterations > 0:
        @parameter
        for i in range(num_iterations):
            temp_phases = phases.copy()
            @parameter
            if i > 0:
                call_back(phases)
            phase_corr_new = phase_correlation(phases, previous_phases, mags, previous_mags, hop_size, window_size)

            lt0 = phase_corr_new.lt(0.0)
            phase_corr_new = abs(phase_corr_new)
            gt_last = phase_corr_new.gt(phase_corr)

            # if the absolute value of the new correlation is higher than the last one, we want to keep it, but if the correlation is negative, we want to invert the phases
            # otherwise we want to keep the old phases. 
            for i2 in range(len(phases)):
                phases[i2] = gt_last.select(lt0.select(wrap_to_pi(phases[i2] + pi), phases[i2]), temp_phases[i2])

            phase_corr = phase_corr_new
    previous_phases = phases.copy()
    previous_mags = mags.copy()