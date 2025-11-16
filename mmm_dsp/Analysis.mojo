from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.BufferedProcess import *

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
struct YIN[window_size: Int, min_freq: Float64, max_freq: Float64](BufferedProcessable):
    """Pitch detection using the original time-domain YIN algorithm.

    YIN needs access to the raw samples so it is a 
    BufferedProcess rather than an FFTProcess.

    This struct is not necessarily intended to be used directly because it is 
    implemented in the PitchYIN struct which takes in single amplitude samples
    and returns a tuple of (pitch, confidence).

    One could use this however if they wanted to put together a suite of audio
    analyses that are all based on the same BufferedProcess.

    Parameters:
        window_size: The size of the analysis window in samples. This should be large enough to capture the lowest frequency of interest.
        min_freq: The minimum frequency to consider for pitch detection.
        max_freq: The maximum frequency to consider for pitch detection.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var pitch: Float64
    var confidence: Float64
    var yin_values: List[Float64]
    var sample_rate: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.pitch = 0.0
        self.confidence = 0.0
        self.yin_values = List[Float64](length=window_size, fill=0.0)
        self.sample_rate = self.world_ptr[].sample_rate
    
    @doc_private
    fn get_messages(mut self):
        # Implemented here to satisfy the BufferedProcessable trait
        pass

    fn next_window(mut self, mut frame: List[Float64]):
        """Compute the YIN pitch estimate for the given frame of audio samples.

        Args:
            frame: The input audio frame of size `window_size`. This List gets passed from BufferedProcess.

        Returns:
            None. The pitch and confidence values are stored in `self.pitch` and `self.confidence`.
        """
        # compute the raw difference function directly in the time domain
        self.yin_values[0] = 0.0
        for tau in range(1, window_size):
            var diff_sum = 0.0
            var limit = window_size - tau
            for i in range(limit):
                var delta = frame[i] - frame[i + tau]
                diff_sum += delta * delta
            self.yin_values[tau] = diff_sum

        # cumulative mean normalized difference function
        var tmp_sum: Float64 = 0.0
        for i in range(1, window_size):
            raw_val = self.yin_values[i]
            tmp_sum += raw_val
            if tmp_sum != 0.0:
                self.yin_values[i] = raw_val * (Float64(i) / tmp_sum)

        var local_pitch = 0.0
        var local_conf = 0.0
        if tmp_sum > 0.0:
            var high_freq = max_freq if max_freq > 0.0 else 1.0
            var low_freq = min_freq if min_freq > 0.0 else 1.0
            var min_bin = Int((self.sample_rate / high_freq) + 0.5)
            var max_bin = Int((self.sample_rate / low_freq) + 0.5)

            if min_bin > window_size - 1:
                min_bin = window_size - 1
            var yin_len = len(self.yin_values)
            if max_bin > yin_len - min_bin - 1:
                max_bin = yin_len - min_bin - 1

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
                    if best_tau > 0 and best_tau < window_size - 1:
                        var prev = self.yin_values[best_tau - 1]
                        var cur = self.yin_values[best_tau]
                        var nxt = self.yin_values[best_tau + 1]
                        var (offset, refined_val) = parabolic_refine(prev, cur, nxt)
                        refined_idx += offset
                        best_val = refined_val

                    if refined_idx > 0.0:
                        local_pitch = self.sample_rate / refined_idx
                        local_conf = max(1.0 - best_val, 0.0)

        self.pitch = local_pitch
        self.confidence = local_conf

struct PitchYIN[window_size: Int, hop_size: Int, min_freq: Float64, max_freq: Float64](Movable,Copyable):
    """Pitch detection using the YIN algorithm.
    
    This struct takes in single amplitude samples and returns a tuple of (pitch, confidence).
    It uses a BufferedProcess internally to manage the audio buffering and windowing.

    Parameters:
        window_size: The size of the analysis window in samples. This should be large enough to capture the lowest frequency of interest.
        hop_size: Pitch analysis will occur every `hop_size` samples (using the most recent `window_size` samples).
        min_freq: The minimum frequency to consider for pitch detection.
        max_freq: The maximum frequency to consider for pitch detection.
    """

    # [TODO] Technically this BufferedProcess doesn't need to return the List[Float64] so there's
    # an extra loop happening after `.next_window()` that can (should) be eliminated.
    var buffered_process: BufferedProcess[YIN[window_size, min_freq, max_freq], window_size, hop_size]
    var world_ptr: UnsafePointer[MMMWorld]
    
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        """Initialize the PitchYIN processor.

        Args:
            world_ptr: A pointer to the MMMWorld.
        """
        self.world_ptr = world_ptr
        self.buffered_process = BufferedProcess[YIN[window_size, min_freq, max_freq], window_size, hop_size](world_ptr,YIN[window_size, min_freq, max_freq](world_ptr))

    fn next(mut self, input: Float64) -> (Float64, Float64):
        """Process the next input sample and return the pitch and confidence.

        Args:
            input: The next audio sample.

        Returns:
            A tuple containing the estimated pitch (in Hz) and confidence (0.0 to 1.0).
        """
        _ = self.buffered_process.next(input)
        return (self.buffered_process.process.pitch, self.buffered_process.process.confidence)