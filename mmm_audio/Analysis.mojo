from mmm_audio import *
from math import ceil, floor, log2, log, exp, sqrt, cos, pi
from math import sqrt

@doc_private
fn parabolic_refine(prev: Float64, cur: Float64, next: Float64) -> Tuple[Float64, Float64]:
    denom = prev - 2.0 * cur + next
    if abs(denom) < 1e-12:
        return (0.0, cur)
    p = 0.5 * (prev - next) / denom
    refined_val = cur - 0.25 * (prev - next) * p
    return (p, refined_val)

trait GetFeaturable:
    fn get_features(self) -> List[Float64]:...

struct YIN(BufferedProcessable,GetFeaturable):
    """Monophonic Frequency ('F0') Detection using the YIN algorithm (FFT-based, O(N log N) version)."""
    var pitch: Float64
    var confidence: Float64
    var sample_rate: Float64
    var fft: RealFFT[]
    var fft_input: List[Float64]
    var fft_power_mags: List[Float64]
    var fft_zero_phases: List[Float64]
    var acf_real: List[Float64]
    var yin_buffer: List[Float64]
    var yin_values: List[Float64]
    var window_size: Int
    var min_freq: Float64
    var max_freq: Float64

    fn __init__(out self, sr: Float64, window_size: Int = 1024, min_freq: Float64 = 20.0, max_freq: Float64 = 20000.0):
        """Initialize the YIN pitch detector.

        Args:
            sr: The sample rate from the MMMWorld.
            window_size: The size of the analysis window in samples.
            min_freq: The minimum frequency to consider for pitch detection.
            max_freq: The maximum frequency to consider for pitch detection.

        Returns:
            An initialized YIN struct.
        """

        self.window_size = window_size
        self.min_freq = min_freq
        self.max_freq = max_freq
        self.pitch = 0.0
        self.confidence = 0.0
        self.sample_rate = sr
        self.fft = RealFFT(window_size * 2)
        self.fft_input = List[Float64](length=window_size * 2, fill=0.0)
        self.fft_power_mags = List[Float64](length=window_size + 1, fill=0.0)
        self.fft_zero_phases = List[Float64](length=window_size + 1, fill=0.0)
        self.acf_real = List[Float64](length=window_size * 2, fill=0.0)
        self.yin_buffer = List[Float64](length=window_size, fill=0.0)
        self.yin_values = List[Float64](length=window_size, fill=0.0)
    
    fn get_features(self) -> List[Float64]:
        """Return the current pitch and confidence as a List of Float64."""
        return [self.pitch, self.confidence]

    fn next_window(mut self, mut frame: List[Float64]):
        """Compute the YIN pitch estimate for the given frame of audio samples.

        Args:
            frame: The input audio frame of size `window_size`. This List gets passed from [BufferedProcess](BufferedProcess.md).
        """

        # 1. Prepare input for FFT (Zero padding)
        for i in range(len(frame)):
            self.fft_input[i] = frame[i]
        for i in range(len(frame), len(self.fft_input)):
            self.fft_input[i] = 0.0
        
        # 2. FFT
        self.fft.fft(self.fft_input)
        
        # 3. Power Spectrum (Mags^2)
        # We use a separate buffer for power mags so we preserve fft_mags for external use
        for i in range(len(self.fft.mags)):
            self.fft_power_mags[i] = self.fft.mags[i] * self.fft.mags[i]
            
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
            var high_freq = self.max_freq if self.max_freq > 0.0 else 1.0
            var low_freq = self.min_freq if self.min_freq > 0.0 else 1.0
            
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

        self.pitch = local_pitch
        self.confidence = local_conf

struct SpectralCentroid(FFTProcessable, GetFeaturable):
    """Spectral Centroid analysis.

    Based on the [Peeters (2003)](http://recherche.ircam.fr/anasyn/peeters/ARTICLES/Peeters_2003_cuidadoaudiofeatures.pdf)
    """

    var sr: Float64
    var centroid: Float64
    var min_freq: Float64
    var max_freq: Float64
    var power_mag: Bool

    fn get_features(self) -> List[Float64]:
        """Return the current spectral centroid value as a List of Float64."""
        return [self.centroid]

    fn __init__(out self, sr: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, power_mag: Bool = False):
        """Initialize the Spectral Centroid analyzer.
        Args:
            sr: The sample rate from the MMMWorld.
            min_freq: The minimum frequency to consider when computing the spectral centroid.
            max_freq: The maximum frequency to consider when computing the spectral centroid.
            power_mag: Whether to use power magnitudes (mags^2) instead of linear magnitudes when computing the centroid.
        
        Returns:
            An initialized SpectralCentroid struct.
        """
        self.sr = sr
        self.centroid = 0.0
        self.min_freq = min_freq
        self.max_freq = max_freq
        self.power_mag = power_mag

    fn next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64]) -> None:
        """Compute the spectral centroid for a given FFT analysis.

        This function is to be used by FFTProcess if SpectralCentroid is passed as the "process".

        Args:
            mags: The input magnitudes as a List of Float64.
            phases: The input phases as a List of Float64.
        """
        self.centroid = self.from_mags(mags, self.sr, self.min_freq, self.max_freq, self.power_mag)

    @staticmethod
    fn from_mags(mags: List[Float64], sample_rate: Float64, min_freq: Float64 = 20, max_freq: Float64 = 20000, power_mag: Bool = False) -> Float64:
        """Compute the spectral centroid for the given magnitudes of an FFT frame.

        This static method is useful when there is an FFT already computed, perhaps as 
        part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

        Args:
            mags: The input magnitudes as a List of Float64.
            sample_rate: The sample rate of the audio signal.
            min_freq: The minimum frequency to consider when computing the spectral centroid.
            max_freq: The maximum frequency to consider when computing the spectral centroid.
            power_mag: Whether to use power magnitudes (mags^2) instead of linear magnitudes when computing the centroid.

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

            m: Float64 = mags[i]

            if power_mag:
                m = m * m

            ampsum += m
            centroid += m * f

        if ampsum > 0.0:
            centroid /= ampsum
        else:
            centroid = 0.0

        return centroid

struct RMS(BufferedProcessable, GetFeaturable):
    """Root Mean Square (RMS) amplitude analysis.
    """
    var rms: Float64

    fn get_features(self) -> List[Float64]:
        """Return the current RMS value as a List of Float64."""
        return [self.rms]

    fn __init__(out self):
        """Initialize the RMS analyzer."""
        self.rms = 0.0

    fn next_window(mut self, mut input: List[Float64]):
        """Compute the RMS for the given window of audio samples.

        This function is to be used with a [BufferedProcess](BufferedProcess.md/#struct-bufferedprocess).

        Args:
            input: The input audio frame of samples. This List gets passed from [BufferedProcess](BufferedProcess.md/#struct-bufferedprocess).
        
        The computed RMS value is stored in self.rms.
        """
        self.rms = self.from_window(input)

    @staticmethod
    fn from_window(mut frame: List[Float64]) -> Float64:
        """Compute the RMS for the given window of audio samples.

        This static method is useful when there is an audio frame already available, perhaps
        as part of a custom struct that implements the [BufferedProcessable](BufferedProcess.md/#trait-bufferedprocessable) trait.

        Args:
            frame: The input audio frame of samples.
        
        Returns:
            Float64. The computed RMS value.
        """
        sum_sq: Float64 = 0.0
        for v in frame:
            sum_sq += v * v
        return sqrt(sum_sq / Float64(len(frame)))

struct MelBands(FFTProcessable, GetFeaturable):
    """Mel Bands analysis.

    This implementation follows the approach used in the [Librosa](https://librosa.org/) library. 
    """

    var sr: Float64
    var weights: List[List[Float64]]
    var bands: List[Float64]
    var num_bands: Int
    var min_freq: Float64
    var max_freq: Float64
    var fft_size: Int
    var power: Float64

    fn get_features(self) -> List[Float64]:
        """Return the current mel band values as a List of Float64."""
        return self.bands.copy()

    fn __init__(out self, sr: Float64, num_bands: Int = 40, min_freq: Float64 = 20.0, max_freq: Float64 = 20000.0, fft_size: Int = 1024, power: Float64 = 2.0):
        """Initialize the Mel Bands analyzer.
        
        Args:
            sr: The sample rate from the MMMWorld.
            num_bands: The number of mel bands to compute.
            min_freq: The minimum frequency (in Hz) to consider when computing the mel bands.
            max_freq: The maximum frequency (in Hz) to consider when computing the mel bands.
            fft_size: The size of the FFT being used to compute the mel bands.
            power: Exponent applied to magnitudes before mel filtering (librosa default is 2.0 for power).
        
        Returns:
            An initialized MelBands struct.
        """
        
        self.sr = sr
        self.num_bands = num_bands
        self.min_freq = min_freq
        self.max_freq = max_freq
        self.fft_size = fft_size
        self.power = power

        self.weights = List[List[Float64]](length=self.num_bands,fill=List[Float64](length=(self.fft_size // 2) + 1, fill=0.0))
        self.bands = List[Float64](length=self.num_bands, fill=0.0)
        self.make_weights()

    fn next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64]) -> None:
        """Compute the mel bands for a given FFT analysis.

        This function is to be used by FFTProcess if MelBands is passed as the "process".

        Nothing is returned from this function, but the computed mel band values are stored in self.bands.

        Args:
            mags: The input magnitudes as a List of Float64.
            phases: The input phases as a List of Float64.
        """
        self.from_mags(mags)

    fn from_mags(mut self, ref mags: List[Float64]):
        """Compute the mel bands for a given list of magnitudes.

        This function is useful when there is an FFT already computed, perhaps as 
        part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

        Args:
            mags: The input magnitudes as a List of Float64.
        """
        for i in range(self.num_bands):
            band_energy: Float64 = 0.0
            for j in range(len(mags)):
                var mag_val: Float64
                if self.power == 1.0:
                    mag_val = mags[j]
                elif self.power == 2.0:
                    mag_val = mags[j] * mags[j]
                else:
                    mag_val = mags[j] ** self.power
                band_energy += self.weights[i][j] * mag_val
            self.bands[i] = band_energy
    
    @doc_private
    fn make_weights(mut self):
        """Compute the mel filter bank weights."""

        fftfreqs = RealFFT.fft_frequencies(sr=self.sr, n_fft=self.fft_size)

        # 'Center freqs' of mel bands - uniformly spaced between limits
        mel_f = MelBands.mel_frequencies(self.num_bands + 2, fmin=self.min_freq, fmax=self.max_freq)

        fdiff = diff(mel_f)
        ramps = subtract_outer(mel_f, fftfreqs)

        for i in range(self.num_bands):
            lower: List[Float64] = List[Float64](length=len(ramps[i]), fill=0.0)
            for j in range(len(ramps[i])):
                lower[j] = -ramps[i][j] / fdiff[i]
            upper: List[Float64] = List[Float64](length=len(ramps[i]), fill=0.0)
            for j in range(len(ramps[i])):
                upper[j] = ramps[i + 2][j] / fdiff[i + 1]

            for j in range(len(ramps[i])):
                self.weights[i][j] = max(0.0, min(lower[j], upper[j]))

        # Slaney-style mel
        var enorm = List[Float64](length=self.num_bands, fill=0.0)
        for i in range(self.num_bands):
            enorm[i] = 2.0 / (mel_f[i + 2] - mel_f[i])
        
        for i in range(self.num_bands):
            for j in range(len(self.weights[i])):
                self.weights[i][j] *= enorm[i]

    @staticmethod
    fn mel_frequencies(n_mels: Int = 128, fmin: Float64 = 0.0, fmax: Float64 = 20000.0) -> List[Float64]:
        """Compute an array of acoustic frequencies tuned to the mel scale.

        This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.mel_frequencies.html).  For more information on mel frequencies space see the [MelBands](Analysis.md/#struct-melbands) documentation.

        Args:
            n_mels: The number of mel bands to generate.
            fmin: The lowest frequency (in Hz).
            fmax: The highest frequency (in Hz).

        Returns:
            A List of Float64 representing the center frequencies of each mel band.
        """

        min_mel = MelBands.hz_to_mel(fmin)
        max_mel = MelBands.hz_to_mel(fmax)

        mels = linspace(min_mel, max_mel, n_mels)

        var hz = List[Float64](length=n_mels, fill=0.0)
        for i in range(n_mels):
            hz[i] = MelBands.mel_to_hz(mels[i])
        return hz^

    @staticmethod
    fn hz_to_mel[num_chans: Int = 1](freq: SIMD[DType.float64,num_chans]) -> SIMD[DType.float64,num_chans]:
        """Convert Hz to Mels.

        This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.hz_to_mel.html). For more information on mel frequencies space see the [MelBands](Analysis.md/#struct-melbands) documentation.

        Parameters:
            num_chans: Size of the SIMD vector. This parameter is inferred by the values passed to the function.

        Args:
            freq: The frequencies in Hz to convert.
        
        Returns:
            The corresponding mel frequencies.
        """

        # "HTK" is a different way to compute mels. It is not implemented in MMMAudio, but
        # commented out here in case it becomes useful in the future.
        # if htk:
        #     return 2595.0 * log10(1.0 + freq / 700.0)

        f_min = 0.0
        f_sp = 200.0 / 3

        mels = (freq - f_min) / f_sp

        min_log_hz = 1000.0  # beginning of log region (Hz)
        min_log_mel = (min_log_hz - f_min) / f_sp  # same (Mels)
        logstep = log(6.4) / 27.0  # step size for log region

        if freq >= min_log_hz:
            mels = min_log_mel + log(freq / min_log_hz) / logstep

        return mels

    @staticmethod
    fn mel_to_hz[num_chans: Int = 1](mel: SIMD[DType.float64,num_chans]) -> SIMD[DType.float64,num_chans]:
        """Convert mel bin numbers to frequencies.

        This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.mel_to_hz.html). For more information on mel frequencies space see the [MelBands](Analysis.md/#struct-melbands) documentation.
        """

        # "HTK" is a different way to compute mels. It is not implemented in MMMAudio, but
        # commented out here in case it becomes useful in the future.
        # if htk:
        #     return 700.0 * (10.0 ** (mel / 2595.0) - 1.0)

        # Fill in the linear scale
        f_min = 0.0
        f_sp = 200.0 / 3
        freq = f_min + f_sp * mel

        # And now the nonlinear scale
        min_log_hz = 1000.0  # beginning of log region (Hz)
        min_log_mel = (min_log_hz - f_min) / f_sp  # same (Mels)
        logstep = log(6.4) / 27.0  # step size for log region

        if mel >= min_log_mel:
            freq = min_log_hz * exp(logstep * (mel - min_log_mel))

        return freq

struct MFCC(FFTProcessable, GetFeaturable):
    """Mel-Frequency Cepstral Coefficients (MFCC) analysis.
    """

    var sr: Float64
    var mel_bands: MelBands
    var db_bands: List[Float64]
    var dct: DCT
    var coeffs: List[Float64]

    fn get_features(self) -> List[Float64]:
        """Return the current MFCC values as a List of Float64."""
        return self.coeffs.copy()

    fn __init__(out self, sr: Float64, num_coeffs: Int = 13, num_bands: Int = 40, min_freq: Float64 = 20.0, max_freq: Float64 = 20000.0, fft_size: Int = 1024):
        """Initialize the MFCC analyzer.

        Args:
            sr: The sample rate for the mel band computation.
            num_coeffs: The number of MFCC coefficients to compute (including the 0th coefficient).
            num_bands: The number of mel bands to use when computing the MFCCs.
            min_freq: The minimum frequency (in Hz) to consider when computing the mel bands for the MFCCs.
            max_freq: The maximum frequency (in Hz) to consider when computing the mel bands for the MFCCs.
            fft_size: The size of the FFT being used to compute the mel bands for the MFCCs.

        Returns:
            An initialized MFCC struct.
        """
        
        self.sr = sr
        self.mel_bands = MelBands(sr, num_bands, min_freq, max_freq, fft_size)
        self.dct = DCT(num_bands, num_coeffs)
        self.db_bands = List[Float64](length=num_bands, fill=0.0)
        self.coeffs = List[Float64](length=num_coeffs, fill=0.0)

    fn next_frame(mut self, mut mags: List[Float64], mut phases: List[Float64]) -> None:
        """Compute the MFCCs for a given FFT analysis.

        This function is to be used by [FFTProcess](FFTProcess.md/#struct-fftprocess) if MFCC is passed as the "process".

        Nothing is returned from this function, but the computed MFCC values are stored in self.coeffs.

        Args:
            mags: The input magnitudes as a List of Float64.
            phases: The input phases as a List of Float64.
        """
        self.from_mags(mags)

    fn from_mags(mut self, ref mags: List[Float64]):
        """Compute the MFCCs for a given list of magnitudes.
        
        This function is useful when there is an FFT already computed, 
        perhaps as part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.
        
        Nothing is returned from this function, but the computed MFCC values are stored in self.coeffs.

        Args:
            mags: The input magnitudes as a List of Float64.
        """
        self.mel_bands.from_mags(mags)
        self.from_mel_bands_internal()

    @doc_private
    fn from_mel_bands_internal(mut self):
        """Compute the MFCCs using self.mel_bands.bands.
        """
        comptime max_db_range: Float64 = 80.0

        var max_db: Float64 = -1.0e30
        for i in range(len(self.mel_bands.bands)):
            var db = power_to_db(self.mel_bands.bands[i])
            self.db_bands[i] = db
            if db > max_db:
                max_db = db

        var min_db = max_db - max_db_range
        for i in range(len(self.db_bands)):
            if self.db_bands[i] < min_db:
                self.db_bands[i] = min_db

        self.dct.process(self.db_bands, self.coeffs)

    fn from_mel_bands(mut self, ref mbands: List[Float64]):
        """Compute the MFCCs for a given list of mel band energies.

        This function is useful when there is a mel band analysis already computed, perhaps as part of a custom struct that implements the [FFTProcessable](FFTProcess.md/#trait-fftprocessable) trait.

        Nothing is returned from this function, but the computed MFCC values are stored in self.coeffs.

        Args:
            mbands: The input mel band energies as a List of Float64.
        """
        comptime max_db_range: Float64 = 80.0

        var max_db: Float64 = -1.0e30
        # iterate over passed mel bands ref:
        for i in range(len(mbands)):
            var db = power_to_db(mbands[i])
            self.db_bands[i] = db
            if db > max_db:
                max_db = db

        var min_db = max_db - max_db_range
        for i in range(len(self.db_bands)):
            if self.db_bands[i] < min_db:
                self.db_bands[i] = min_db

        self.dct.process(self.db_bands, self.coeffs)

struct DCT(Movable,Copyable):
    """Compute the Discrete Cosine Transform (DCT)."""

    var weights: List[List[Float64]]
    var input_size: Int
    var output_size: Int

    fn __init__(out self, input_size: Int, output_size: Int):
        self.input_size = input_size
        self.output_size = output_size
        self.weights = List[List[Float64]](length=output_size, fill=List[Float64](length=input_size, fill=0.0))
        self.make_weights()

    fn process(mut self, ref input: List[Float64], mut output: List[Float64]) -> None:
        """Compute the first `output_size` DCT-II coefficients for `input`.

        Nothing is returned from this function, but the computed DCT coefficients are stored in the `output` List passed as an argument.

        Args:
            input: Input vector of length `input_size`.
            output: Output vector of length `output_size`.
        """
        for k in range(self.output_size):
            var acc: Float64 = 0.0
            for n in range(self.input_size):
                acc += self.weights[k][n] * input[n]
            output[k] = acc

    @doc_private
    fn make_weights(mut self):
        """Precompute the DCT-II weight matrix."""
        var n_inv = 1.0 / Float64(self.input_size)
        var scale0 = sqrt(n_inv)
        var scale = sqrt(2.0 * n_inv)
        var n_f = Float64(self.input_size)

        for k in range(self.output_size):
            var alpha = scale0 if k == 0 else scale
            var k_f = Float64(k)
            for n in range(self.input_size):
                var n_f_idx = Float64(n) + 0.5
                var angle = (pi / n_f) * n_f_idx * k_f
                self.weights[k][n] = alpha * cos(angle)
