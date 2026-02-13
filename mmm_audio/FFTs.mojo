from .MMMWorld_Module import *
from complex import *
import math as Math
from random import random_float64

@doc_private
fn log2_int(n: Int) -> Int:
    """Compute log base 2 of an integer (assuming n is power of 2)."""
    var result = 0
    var temp = n
    while temp > 1:
        temp >>= 1
        result += 1
    return result

struct RealFFT[num_chans: Int = 1](Copyable, Movable):
    """Real-valued FFT implementation using Cooley-Tukey algorithm.

    If you're looking to create an FFT-based FX, look to the [FFTProcessable](FFTProcess.md/#trait-fftprocessable)
    trait used in conjunction with [FFTProcess](FFTProcess.md/#struct-fftprocess) instead. This struct is a 
    lower-level implementation that provides
    FFT and inverse FFT on fixed windows of real values. [FFTProcessable](FFTProcess.md/#trait-fftprocessable) structs will enable you to 
    send audio samples (such as in a custom struct's `.next()` `fn`) *into* and *out of* 
    an FFT, doing some manipulation of the magnitudes and phases in between. ([FFTProcess](FFTProcess.md/#struct-fftprocess)
    has this RealFFT struct inside of it.)

    Parameters:
        num_chans: Number of channels for SIMD processing.
    """
    var result: List[ComplexSIMD[DType.float64, Self.num_chans]]
    var reversed: List[ComplexSIMD[DType.float64, Self.num_chans]]   
    var mags: List[SIMD[DType.float64, Self.num_chans]]
    var phases: List[SIMD[DType.float64, Self.num_chans]]
    var w_ms: List[ComplexSIMD[DType.float64, Self.num_chans]]
    var bit_reverse_lut: List[Int]
    var packed_freq: List[ComplexSIMD[DType.float64, Self.num_chans]]
    var unpacked: List[ComplexSIMD[DType.float64, Self.num_chans]]
    var unpack_twiddles: List[ComplexSIMD[DType.float64, Self.num_chans]]
    var log_n: Int
    var log_n_full: Int
    var scale: Float64
    var window_size: Int

    fn __init__(out self, window_size: Int):
        """Initialize the RealFFT struct.
        
        All internal buffers and lookup tables are set up here based on the Parameters.

        """
        self.log_n = log2_int(window_size//2)
        self.log_n_full = log2_int(window_size)
        self.scale = 1.0 / Float64(window_size)

        self.window_size = window_size
        self.result = List[ComplexSIMD[DType.float64, Self.num_chans]](capacity=window_size // 2)
        self.reversed = List[ComplexSIMD[DType.float64, Self.num_chans]](capacity=window_size)
        self.mags = List[SIMD[DType.float64, Self.num_chans]](capacity=window_size // 2 + 1)
        self.phases = List[SIMD[DType.float64, Self.num_chans]](capacity=window_size // 2 + 1)
        for _ in range(window_size // 2):
            self.result.append(ComplexSIMD[DType.float64, Self.num_chans](0.0, 0.0))
        for _ in range(window_size):
            self.reversed.append(ComplexSIMD[DType.float64, Self.num_chans](0.0, 0.0))
        for _ in range(window_size//2 + 1):
            self.mags.append(SIMD[DType.float64, Self.num_chans](0.0))
            self.phases.append(SIMD[DType.float64, Self.num_chans](0.0))
        self.w_ms = List[ComplexSIMD[DType.float64, Self.num_chans]](capacity=self.log_n // 2)
        for i in range(self.log_n // 2):
            self.w_ms.append(ComplexSIMD[DType.float64, Self.num_chans](
                Math.cos(2.0 * Math.pi / Float64(1 << (i + 1))),
                -Math.sin(2.0 * Math.pi / Float64(1 << (i + 1)))
            ))
        

        self.unpack_twiddles = List[ComplexSIMD[DType.float64, Self.num_chans]](capacity=window_size // 2)
        for k in range(window_size // 2):
            var angle = -2.0 * Math.pi * Float64(k) / Float64(window_size)
            self.unpack_twiddles.append(ComplexSIMD[DType.float64, Self.num_chans](
                Math.cos(angle), Math.sin(angle)
            ))

        self.packed_freq = List[ComplexSIMD[DType.float64, Self.num_chans]](capacity=window_size // 2)
        for _ in range(window_size // 2):
            self.packed_freq.append(ComplexSIMD[DType.float64, Self.num_chans](0.0, 0.0))

        self.unpacked = List[ComplexSIMD[DType.float64, Self.num_chans]](capacity=window_size)
        for _ in range(window_size):
            self.unpacked.append(ComplexSIMD[DType.float64, Self.num_chans](0.0, 0.0))

        self.bit_reverse_lut = List[Int](capacity=window_size // 2)
        for i in range(window_size // 2):
            self.bit_reverse_lut.append(self.bit_reverse(i, self.log_n))  # Full window_size

    @doc_private
    fn bit_reverse(self,num: Int, bits: Int) -> Int:
        """Reverse the bits of a number."""
        var result = 0
        var n = num
        for _ in range(bits):
            result = (result << 1) | (n & 1)
            n >>= 1
        return result

    fn fft(mut self, input: List[SIMD[DType.float64, Self.num_chans]]):
        """Compute the FFT of the input real-valued samples.
        
        The resulting magnitudes and phases are stored in the internal `mags` and `phases` lists.
        
        Args:
            input: The input real-valued samples to transform. This can be a List of SIMD vectors for multi-channel processing or a List of Float64 for single-channel processing.
        """
        self._compute_fft(input)
        # Compute magnitudes and phases
        for i in range(self.window_size // 2 + 1):
            self.mags[i] = self.result[i].norm()
            self.phases[i] = Math.atan2(self.result[i].im, self.result[i].re)

    fn fft(mut self, input: List[SIMD[DType.float64, Self.num_chans]], mut mags: List[SIMD[DType.float64, Self.num_chans]], mut phases: List[SIMD[DType.float64, Self.num_chans]]):
        """Compute the FFT of the input real-valued samples.
        
        The resulting magnitudes and phases are stored in the provided lists.
        
        Args:
            input: The input real-valued samples to transform. This can be a List of SIMD vectors for multi-channel processing or a List of Float64 for single-channel processing.
            mags: A mutable list to store the magnitudes of the FFT result.
            phases: A mutable list to store the phases of the FFT result.
        """
        self._compute_fft(input)
        # Compute magnitudes and phases
        for i in range(self.window_size // 2 + 1):
            mags[i] = self.result[i].norm()
            phases[i] = Math.atan2(self.result[i].im, self.result[i].re)

    @doc_private
    fn _compute_fft(mut self, input: List[SIMD[DType.float64, Self.num_chans]]):
        for i in range(self.window_size // 2):
            var real_part = input[2 * i]
            var imag_part = input[2 * i + 1]
            self.result[self.bit_reverse_lut[i]] = ComplexSIMD[DType.float64, Self.num_chans](real_part, imag_part)

        for stage in range(1, self.log_n + 1):
            var m = 1 << stage
            var half_m = m >> 1
            
            stage_twiddle = ComplexSIMD[DType.float64, Self.num_chans](
                Math.cos(2.0 * Math.pi / Float64(m)),
                -Math.sin(2.0 * Math.pi / Float64(m))
            )

            for k in range(0, self.window_size // 2, m):
                var w = ComplexSIMD[DType.float64, Self.num_chans](1.0, 0.0)
                
                for j in range(half_m):
                    var idx1 = k + j
                    var idx2 = k + j + half_m
                    
                    var t = w * self.result[idx2]
                    var u = self.result[idx1]
                    
                    self.result[idx1] = u + t
                    self.result[idx2] = u - t

                    w = w * stage_twiddle

        for k in range(self.window_size // 2 + 1):
            if k == 0:
                # DC components
                var X_even_0 = (self.result[0].re + self.result[0].re) * 0.5  # Real part
                var X_odd_0 = (self.result[0].im + self.result[0].im) * 0.5   # Imag part
                self.unpacked[0] = ComplexSIMD[DType.float64, Self.num_chans](X_even_0 + X_odd_0, SIMD[DType.float64, Self.num_chans](0.0))
                if self.window_size > 1:
                    self.unpacked[self.window_size // 2] = ComplexSIMD[DType.float64, Self.num_chans](X_even_0 - X_odd_0, SIMD[DType.float64, Self.num_chans](0.0))
            elif k < self.window_size // 2:
                var Gk = self.result[k]
                var Gk_conj = self.result[self.window_size // 2 - k].conj()
                
                var X_even_k = (Gk + Gk_conj) * 0.5
                var X_odd_k = (Gk - Gk_conj) * ComplexSIMD[DType.float64, Self.num_chans](0.0, -0.5)
                
                var twiddle = self.unpack_twiddles[k]
                var X_odd_k_rotated = X_odd_k * twiddle
                
                self.unpacked[k] = X_even_k + X_odd_k_rotated
                self.unpacked[self.window_size - k] = (X_even_k - X_odd_k_rotated).conj()

        self.result.clear()
        self.result.resize(self.window_size, ComplexSIMD[DType.float64, Self.num_chans](0.0, 0.0))
        for i in range(self.window_size):
            self.result[i] = self.unpacked[i]

    fn ifft(mut self, mut output: List[SIMD[DType.float64, Self.num_chans]]):
        """Compute the inverse FFT using the internal magnitudes and phases.
        
        The output real-valued samples are written to the provided output list.

        Args:
            output: A mutable list to store the output real-valued samples.
        """
        
        for k in range(self.window_size // 2 + 1):
            if k < len(self.mags):
                var mag = self.mags[k]
                var phase = self.phases[k]
                
                var real_part = mag * Math.cos(phase)
                var imag_part = mag * Math.sin(phase)
                
                self.result[k] = ComplexSIMD[DType.float64, Self.num_chans](real_part, imag_part)
        
        self._compute_inverse_fft(output)

    fn ifft(mut self, mags: List[SIMD[DType.float64, Self.num_chans]], phases: List[SIMD[DType.float64, Self.num_chans]], mut output: List[SIMD[DType.float64, Self.num_chans]]):
        """Compute the inverse FFT using the provided magnitudes and phases.
        
        The output real-valued samples are written to the provided output list.

        Args:
            mags: A list of magnitudes for the inverse FFT.
            phases: A list of phases for the inverse FFT.
            output: A mutable list to store the output real-valued samples.
        """
        
        for k in range(self.window_size // 2 + 1):
            if k < len(mags):
                var mag = mags[k]
                var phase = phases[k]
                
                var real_part = mag * Math.cos(phase)
                var imag_part = mag * Math.sin(phase)
                
                self.result[k] = ComplexSIMD[DType.float64, Self.num_chans](real_part, imag_part)
        
        self._compute_inverse_fft(output)

    @doc_private
    fn _compute_inverse_fft(mut self, mut output: List[SIMD[DType.float64, Self.num_chans]]):
        for k in range(1, self.window_size // 2):  # k=1 to size//2-1
            self.result[self.window_size - k] = self.result[k].conj()

        self.result[0] = ComplexSIMD[DType.float64, Self.num_chans](self.result[0].re, SIMD[DType.float64, Self.num_chans](0.0))
        self.result[self.window_size // 2] = ComplexSIMD[DType.float64, Self.num_chans](self.result[self.window_size // 2].re, SIMD[DType.float64, Self.num_chans](0.0))
        
        #  this should be a variable, but it won't let me make it one!
        for i in range(self.window_size):
            self.reversed[self.bit_reverse(i, self.log_n_full)] = self.result[i]

        for stage in range(1, self.log_n_full + 1):
            var m = 1 << stage
            var half_m = m >> 1
            
            var stage_twiddle = ComplexSIMD[DType.float64, Self.num_chans](
                Math.cos(2.0 * Math.pi / Float64(m)),
                Math.sin(2.0 * Math.pi / Float64(m))
            )
            
            for k in range(0, self.window_size, m):
                var w = ComplexSIMD[DType.float64, Self.num_chans](1.0, 0.0)
                
                for j in range(half_m):
                    var idx1 = k + j
                    var idx2 = k + j + half_m

                    var t = w * self.reversed[idx2]
                    var u = self.reversed[idx1]

                    self.reversed[idx1] = u + t
                    self.reversed[idx2] = u - t
                    w = w * stage_twiddle
        
        # Extract real parts
        for i in range(min(self.window_size, len(output))):
            output[i] = self.reversed[i].re * self.scale
    
    @staticmethod
    fn fft_frequencies(sr: Float64, n_fft: Int, min_bin: Int = 0, num_bins: Int = -1) -> List[Float64]:
        """Compute the FFT bin center frequencies.

        This implementation is based on Librosa's eponymous [function](https://librosa.org/doc/main/generated/librosa.fft_frequencies.html).

        Args:
            sr: The sample rate of the audio signal.
            n_fft: The size of the FFT.
            min_bin: The minimum FFT bin index to include.
            num_bins: The number of FFT bins to include. Defaults to all bins from min_bin to n_fft//2.

        Returns:
            A List of Float64 representing the center frequencies of each FFT bin.
        """
        var nyquist_bin = n_fft // 2
        var min_b = max(min_bin, 0)
        var max_possible = nyquist_bin - min_b + 1
        var count = num_bins
        if count < 0 or count > max_possible:
            count = max_possible
        if count <= 0:
            return List[Float64]()
        binHz = sr / Float64(n_fft)
        freqs = List[Float64](length=count, fill=0.0)
        for i in range(count):
            freqs[i] = Float64(min_b + i) * binHz
        return freqs^