from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.BufferedProcess import *
from mmm_dsp.FFTProcess import *
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

# [TODO] Implement the YINFFT optimized algorithm because this one is O(n^2) while
# the FFT based version is O(n log n). The FFT version also requires to know the 
# raw amplitude samples, so it would also be a BufferedProcess rather than an FFTProcess.
struct YIN[min_freq: Float64 = 20, max_freq: Float64 = 20000](BufferedProcessable):
    """Monophonic Frequency ('F0') Detection using the original time-domain YIN algorithm.

    > The YIN algorithm seems to work best with no windowing applied to the audio frame.

    YIN needs access to the raw samples so it is 
    BufferedProcessable rather than an FFTProcessable.

    This struct can be used with a BufferedInput to manage buffering or
    the `from_window` static method can be used directly on audio frames 
    inside a custom BufferedProcessable struct (or anywhere else a List 
    of samples is available).

    Parameters:
        min_freq: The minimum frequency to consider for pitch detection.
        max_freq: The maximum frequency to consider for pitch detection.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var pitch: Float64
    var confidence: Float64
    var sample_rate: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.pitch = 0.0
        self.confidence = 0.0
        self.sample_rate = self.world_ptr[].sample_rate
    
    @staticmethod
    fn from_window(frame: List[Float64], sample_rate: Float64) -> (Float64, Float64):
        """Static method to compute the YIN pitch estimate for a given frame of audio samples.

        Args:
            frame: The input audio frame of size `window_size`.

        Returns:
            A tuple containing the estimated pitch (in Hz) and confidence (0.0 to 1.0).
        """
        # compute the raw difference function directly in the time domain
        window_size = len(frame)
        yin_values = List[Float64](length=window_size, fill=0.0)
        for tau in range(1, window_size):
            var diff_sum = 0.0
            var limit = window_size - tau
            for i in range(limit):
                var delta = frame[i] - frame[i + tau]
                diff_sum += delta * delta
            yin_values[tau] = diff_sum

        # cumulative mean normalized difference function
        var tmp_sum: Float64 = 0.0
        for i in range(1, window_size):
            raw_val = yin_values[i]
            tmp_sum += raw_val
            if tmp_sum != 0.0:
                yin_values[i] = raw_val * (Float64(i) / tmp_sum)

        var local_pitch = 0.0
        var local_conf = 0.0
        if tmp_sum > 0.0:
            var high_freq = max_freq if max_freq > 0.0 else 1.0
            var low_freq = min_freq if min_freq > 0.0 else 1.0
            # [TOD0] should this just be ceil/floor?
            var min_bin = Int((sample_rate / high_freq) + 0.5)
            var max_bin = Int((sample_rate / low_freq) + 0.5)

            if min_bin > window_size - 1:
                min_bin = window_size - 1
            var yin_len = len(yin_values)
            if max_bin > yin_len - min_bin - 1:
                max_bin = yin_len - min_bin - 1

            if max_bin > min_bin:
                var best_tau = -1
                var best_val = 1.0
                var threshold: Float64 = 0.1
                var tau = min_bin
                while tau < max_bin:
                    var val = yin_values[tau]
                    if val < threshold:
                        while tau + 1 < max_bin and yin_values[tau + 1] < val:
                            tau += 1
                            val = yin_values[tau]
                        best_tau = tau
                        best_val = val
                        break
                    if val < best_val:
                        best_tau = tau
                        best_val = val
                    tau += 1

                if best_tau > 0:
                    var refined_idx = Float64(best_tau)
                    if best_tau > 0 and best_tau < window_size - 1:
                        var prev = yin_values[best_tau - 1]
                        var cur = yin_values[best_tau]
                        var nxt = yin_values[best_tau + 1]
                        var (offset, refined_val) = parabolic_refine(prev, cur, nxt)
                        refined_idx += offset
                        best_val = refined_val

                    if refined_idx > 0.0:
                        local_pitch = sample_rate / refined_idx
                        local_conf = max(1.0 - best_val, 0.0)

        return (local_pitch, local_conf)

    fn next_window(mut self, mut frame: List[Float64]):
        """Compute the YIN pitch estimate for the given frame of audio samples.

        Args:
            frame: The input audio frame of size `window_size`. This List gets passed from BufferedProcess.

        Returns:
            None. The pitch and confidence values are stored in `self.pitch` and `self.confidence`.
        """
        self.pitch, self.confidence = self.from_window(frame, self.sample_rate)

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
    var buffered_input: BufferedInput[YIN[min_freq, max_freq], window_size, hop_size]
    var world_ptr: UnsafePointer[MMMWorld]
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the Pitch processor.

        Args:
            world_ptr: A pointer to the MMMWorld.
        """
        self.world_ptr = world_ptr
        self.buffered_input = BufferedInput[YIN[min_freq, max_freq], window_size, hop_size](world_ptr,YIN[min_freq, max_freq](world_ptr))

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

        Returns:
            None. The centroid value is stored in `self.centroid`.
        """
        self.centroid = self.from_mags(mags, self.world_ptr[].sample_rate)

    @staticmethod
    fn from_mags(mags: List[Float64], sample_rate: Float64) -> Float64:
        """Compute the spectral centroid for the given FFT frame.

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