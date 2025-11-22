from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.BufferedProcess import *
from mmm_dsp.FFTProcess import *
from mmm_dsp.FFT import FFT
from math import ceil, floor, log2
from mmm_utils.functions import cpsmidi, ampdb
from math import sqrt

struct Units:
    alias hz: Int = 0
    alias midi: Int = 1
    alias db: Int = 2
    alias amp: Int = 3

@doc_private
fn parabolic_refine(prev: Float64, cur: Float64, next: Float64) -> (Float64, Float64):
    denom = prev - 2.0 * cur + next
    if abs(denom) < 1e-12:
        return (0.0, cur)
    p = 0.5 * (prev - next) / denom
    refined_val = cur - 0.25 * (prev - next) * p
    return (p, refined_val)

struct YIN[window_size: Int, min_freq: Float64 = 20, max_freq: Float64 = 20000, units: Int = Units.hz](BufferedProcessable):
    """Monophonic Frequency ('F0') Detection using the YIN algorithm.

    This implementation uses FFT-based autocorrelation for performance (O(N log N)).

    Parameters:
        window_size: The size of the analysis window in samples.
        min_freq: The minimum frequency to consider for pitch detection.
        max_freq: The maximum frequency to consider for pitch detection.
        units: The units for the pitch output. Use the Units struct (e.g., Units.hz or Units.midi).
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var pitch: Float64
    var confidence: Float64
    var sample_rate: Float64
    var fft: FFT[window_size * 2]
    var fft_input: List[Float64]
    var fft_mags: List[Float64]
    var fft_phases: List[Float64]
    var fft_power_mags: List[Float64]
    var fft_zero_phases: List[Float64]
    var acf_real: List[Float64]
    var yin_buffer: List[Float64]
    var yin_values: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.pitch = 0.0
        self.confidence = 0.0
        self.sample_rate = self.world_ptr[].sample_rate
        self.fft = FFT[window_size * 2]()
        self.fft_input = List[Float64](length=window_size * 2, fill=0.0)
        self.fft_mags = List[Float64](length=window_size + 1, fill=0.0)
        self.fft_phases = List[Float64](length=window_size + 1, fill=0.0)
        self.fft_power_mags = List[Float64](length=window_size + 1, fill=0.0)
        self.fft_zero_phases = List[Float64](length=window_size + 1, fill=0.0)
        self.acf_real = List[Float64](length=window_size * 2, fill=0.0)
        self.yin_buffer = List[Float64](length=window_size, fill=0.0)
        self.yin_values = List[Float64](length=window_size, fill=0.0)
    
    fn next_window(mut self, mut frame: List[Float64]):
        """Compute the YIN pitch estimate for the given frame of audio samples.

        Args:
            frame: The input audio frame of size `window_size`. This List gets passed from BufferedProcess.
        """
        # 1. Prepare input for FFT (Zero padding)
        for i in range(len(frame)):
            self.fft_input[i] = frame[i]
        for i in range(len(frame), len(self.fft_input)):
            self.fft_input[i] = 0.0
        
        # 2. FFT
        self.fft.fft(self.fft_input, self.fft_mags, self.fft_phases)
        
        # 3. Power Spectrum (Mags^2)
        # We use a separate buffer for power mags so we preserve fft_mags for external use
        for i in range(len(self.fft_mags)):
            self.fft_power_mags[i] = self.fft_mags[i] * self.fft_mags[i]
            
        # 4. IFFT -> Autocorrelation
        # Use zero phases for autocorrelation
        self.fft.ifft(self.fft_power_mags, self.fft_zero_phases, self.acf_real)
        
        # 5. Compute Difference Function
        var total_energy = self.acf_real[0]
        
        var running_sum = 0.0
        for i in range(len(frame)):
            running_sum += frame[i] * frame[i]
            self.yin_buffer[i] = running_sum
            
        self.yin_values[0] = 1.0 
        
        for tau in range(1, len(frame)):
             var term1 = self.yin_buffer[len(frame) - 1 - tau]
             var term2 = total_energy
             if tau > 0:
                 term2 -= self.yin_buffer[tau - 1]
             var term3 = 2.0 * self.acf_real[tau]
             
             self.yin_values[tau] = term1 + term2 - term3

        # cumulative mean normalized difference function
        var tmp_sum: Float64 = 0.0
        for i in range(1, len(frame)):
            raw_val = self.yin_values[i]
            tmp_sum += raw_val
            if tmp_sum != 0.0:
                self.yin_values[i] = raw_val * (Float64(i) / tmp_sum)
            else:
                self.yin_values[i] = 1.0

        var local_pitch = 0.0
        var local_conf = 0.0
        if tmp_sum > 0.0:
            var high_freq = max_freq if max_freq > 0.0 else 1.0
            var low_freq = min_freq if min_freq > 0.0 else 1.0
            
            var min_bin = Int((self.sample_rate / high_freq) + 0.5)
            var max_bin = Int((self.sample_rate / low_freq) + 0.5)

            # Clamp min_bin
            if min_bin < 1:
                min_bin = 1
                
            # Clamp max_bin
            var safe_limit = len(frame) // 2
            if max_bin > safe_limit:
                max_bin = safe_limit

            if max_bin > min_bin:
                var best_tau = -1
                var best_val = 1.0
                var threshold: Float64 = 0.1
                var tau = min_bin
                while tau < max_bin:
                    var val = self.yin_values[tau]
                    if val < threshold:
                        while tau + 1 < max_bin and self.yin_values[tau + 1] < val:
                            tau += 1
                            val = self.yin_values[tau]
                        best_tau = tau
                        best_val = val
                        break
                    if val < best_val:
                        best_tau = tau
                        best_val = val
                    tau += 1

                if best_tau > 0:
                    var refined_idx = Float64(best_tau)
                    if best_tau > 0 and best_tau < len(frame) - 1:
                        var prev = self.yin_values[best_tau - 1]
                        var cur = self.yin_values[best_tau]
                        var nxt = self.yin_values[best_tau + 1]
                        var (offset, refined_val) = parabolic_refine(prev, cur, nxt)
                        refined_idx += offset
                        best_val = refined_val

                    if refined_idx > 0.0:
                        local_pitch = self.sample_rate / refined_idx
                        local_conf = max(1.0 - best_val, 0.0)
                        local_conf = min(local_conf, 1.0)

                    if units == Units.midi:
                        local_pitch = cpsmidi(local_pitch)

        self.pitch = local_pitch
        self.confidence = local_conf

struct Pitch[window_size: Int, hop_size: Int, min_freq: Float64, max_freq: Float64](Movable,Copyable):
    """Monophonic Frequency ('F0') detection using the YIN algorithm.
    
    This Pitch struct is a higher-level interface to the YIN algorithm. This struct 
    takes in single amplitude samples and returns a tuple of (pitch, confidence).
    It uses a BufferedInput internally to manage the audio buffering. 
    
    > The actual YIN algorithm seems to work best when there is no windowing applied to the audio frame.

    If multiple buffered analyses or processes are being conducted on the same source signal,
    consider using the YIN struct directly within a custom BufferedProcess to avoid redundant buffering.
    See the AnalysisExample file.

    Parameters:
        window_size: The size of the analysis window in samples. This should be large enough to capture the lowest frequency of interest.
        hop_size: Analysis will occur every `hop_size` samples (using the most recent `window_size` samples).
        min_freq: The minimum frequency to consider for pitch detection.
        max_freq: The maximum frequency to consider for pitch detection.
    """

    # [TODO] Technically this BufferedProcess doesn't need to return the List[Float64] so there's
    # an extra loop happening after `.next_window()` that can (should) be eliminated.
    var buffered_input: BufferedInput[YIN[window_size, min_freq, max_freq], window_size, hop_size]
    var world_ptr: UnsafePointer[MMMWorld]
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the Pitch processor.

        Args:
            world_ptr: A pointer to the MMMWorld.
        """
        self.world_ptr = world_ptr
        self.buffered_input = BufferedInput[YIN[window_size, min_freq, max_freq], window_size, hop_size](world_ptr,YIN[window_size, min_freq, max_freq](world_ptr))

    fn next(mut self, input: Float64) -> (Float64, Float64):
        """Process the next input sample and return the pitch and confidence.

        Args:
            input: The next audio sample.

        Returns:
            A tuple containing the estimated pitch (in Hz) and confidence (0.0 to 1.0).
        """
        self.buffered_input.next(input)
        return (self.buffered_input.process.pitch, self.buffered_input.process.confidence)

struct SpectralCentroid[min_freq: Float64 = 20, max_freq: Float64 = 20000, power_mag: Bool = False, unit: Int = 0](Movable,Copyable):
    """Spectral Centroid analysis.

    Parameters:
        min_freq: The minimum frequency (in Hz) to consider when computing the centroid.
        max_freq: The maximum frequency (in Hz) to consider when computing the centroid.
        power_mag: If True, use power magnitudes (squared) for the centroid calculation.
        unit: The unit for the output centroid value. Use `Units.hz` for Hertz or `Units.midi` for MIDI note number.
    """

    var world_ptr: UnsafePointer[MMMWorld]
    var centroid: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.centroid = 0.0

        if unit in [Units.hz, Units.midi]:
            pass
        else:
            print("SpectralCentroid: Invalid unit parameter. Must be Units.hz or Units.midi. Defaulting to Hz.")

    fn next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64]) -> None:
        """Compute the spectral centroid for the given FFT frame.

        Args:
            mags: The input magnitudes as a List of Float64.
            phases: The input phases as a List of Float64.
        """
        self.centroid = self.from_mags(mags, self.world_ptr[].sample_rate)

    @staticmethod
    fn from_mags(mags: List[Float64], sample_rate: Float64) -> Float64:
        """Compute the spectral centroid for the given magnitudes of an FFT frame.

        Args:
            mags: The input magnitudes as a List of Float64.
            sample_rate: The sample rate of the audio signal.

        Returns:
            Float64. The spectral centroid value.
        """
        
        fft_size: Int = (len(mags) - 1) * 2
        binHz: Float64 = sample_rate / fft_size

        min_bin = Int(ceil(min_freq / binHz))
        max_bin = Int(floor(max_freq / binHz))
        
        min_bin = max(min_bin, 0)
        max_bin = min(max_bin, fft_size // 2)
        max_bin = max(max_bin, min_bin)

        centroid: Float64 = 0.0
        ampsum: Float64 = 0.0

        for i in range(min_bin, max_bin):
            f: Float64 = i * binHz

            @parameter
            if unit == Units.midi:
                f = cpsmidi(f)

            m: Float64 = mags[i]

            @parameter
            if power_mag:
                m = m * m

            ampsum += m
            centroid += m * f

        if ampsum > 0.0:
            centroid /= ampsum
        else:
            centroid = 0.0

        return centroid

struct RMS[unit: Int = Units.db](BufferedProcessable):
    var rms: Float64

    fn __init__(out self):
        if unit not in [Units.db, Units.amp]:
            print("RMS: Invalid unit parameter. Must be Units.db or Units.amp. Defaulting to db.")
        
        if unit == Units.amp:
            self.rms = 0.0
        else:
            self.rms = -130.0

    fn next_window(mut self, mut input: List[Float64]) -> None:
        self.rms = self.from_window(input)

    @staticmethod
    fn from_window(mut frame: List[Float64]) -> Float64:
        sum_sq: Float64 = 0.0
        for v in frame:
            sum_sq += v * v
        rms: Float64 = sqrt(sum_sq / Float64(len(frame)))

        @parameter
        if unit == Units.db:
            return ampdb(rms)
        elif unit == Units.amp:
            return rms
        else:
            print("RMS: Invalid unit parameter. Must be Units.db or Units.amp. Defaulting to db.")
            return ampdb(rms)