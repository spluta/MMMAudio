from mmm_src.MMMWorld import *
from complex import *
import math as Math
from random import random_float64

struct FFT[window_size: Int = 1024](Movable,Copyable):
    var py_input: PythonObject
    var np: PythonObject
    var py_complex: PythonObject

    fn __init__(out self):
        # Currently the guts are numpy. This should be swapped out when a faster, more
        # native FFT is available.
        self.py_input = PythonObject(None)
        self.np = PythonObject(None)
        self.py_complex = PythonObject(None)
        try:
            self.np = Python.import_module("numpy")
            self.py_input = self.np.zeros(window_size)  
            self.py_complex = self.np.zeros((window_size // 2) + 1, dtype=self.np.complex64)
        except err:
            print("Error importing numpy.fft")
    
    fn fft(mut self, input: List[Float64], mut complex: List[ComplexFloat64]) -> None:
        try:
            for i in range(len(input)):
                self.py_input[i] = input[i]
            self.py_complex = self.np.fft.rfft(self.py_input)
            for i in range(len(self.py_complex)):
                complex[i].re = Float64(self.py_complex[i].real)
                complex[i].im = Float64(self.py_complex[i].imag)
        except err:
            print(err)
    
    fn fft(mut self, input: List[Float64], mut mags: List[Float64], mut phases: List[Float64]) -> None:
        try:
            for i in range(len(input)):
                self.py_input[i] = input[i]
            self.py_complex = self.np.fft.rfft(self.py_input)
            for i in range(len(self.py_complex)):
                mags[i] = Float64(self.np.abs(self.py_complex[i]))
                phases[i] = Float64(self.np.angle(self.py_complex[i]))
        except err:
            print(err)
    
    fn ifft(mut self, complex: List[ComplexFloat64], mut output: List[Float64]) -> None:
        try:
            for i in range(len(complex)):
                self.py_complex[i] = self.np.complex64(complex[i].re, complex[i].im)
            self.py_input = self.np.fft.irfft(self.py_complex)
            for i in range(len(output)):
                output[i] = Float64(self.py_input[i])
        except err:
            print(err)
    
    fn ifft(mut self, mags: List[Float64], phases: List[Float64], mut output: List[Float64]) -> None:
        try:
            for i in range(len(mags)):
                self.py_complex[i] = self.np.complex64(mags[i] * self.np.cos(phases[i]), mags[i] * self.np.sin(phases[i]))
            self.py_input = self.np.fft.irfft(self.py_complex)
            for i in range(len(output)):
                output[i] = Float64(self.py_input[i])
        except err:
            print(err)

fn log2_int(n: Int) -> Int:
    """Compute log base 2 of an integer (assuming n is power of 2)."""
    var result = 0
    var temp = n
    while temp > 1:
        temp >>= 1
        result += 1
    return result

struct RealFFT[size: Int = 1024](Copyable, Movable):
    alias log_n: Int = log2_int(size//2)
    alias log_n_full: Int = log2_int(size)
    alias scale: Float64 = 1.0 / Float64(size)
    var bit_reverse_lut: List[Int]

    var result: List[ComplexSIMD[DType.float64, 1]]
    var reversed: List[ComplexSIMD[DType.float64, 1]]   
    var mags: List[SIMD[DType.float64, 1]]
    var phases: List[SIMD[DType.float64, 1]]
    var w_ms: List[ComplexSIMD[DType.float64, 1]]
    
    var packed_freq: List[ComplexSIMD[DType.float64, 1]]
    var unpacked: List[ComplexSIMD[DType.float64, 1]]
    var unpack_twiddles: List[ComplexSIMD[DType.float64, 1]]

    var result2: List[ComplexSIMD[DType.float64, 2]]
    var reversed2: List[ComplexSIMD[DType.float64, 2]]   
    var mags2: List[SIMD[DType.float64, 2]]
    var phases2: List[SIMD[DType.float64, 2]]
    var w_ms2: List[ComplexSIMD[DType.float64, 2]]
    var packed_freq2: List[ComplexSIMD[DType.float64, 2]]
    var unpacked2: List[ComplexSIMD[DType.float64, 2]]
    var unpack_twiddles2: List[ComplexSIMD[DType.float64, 2]]



    fn __init__(out self):
        self.result = List[ComplexSIMD[DType.float64, 1]](capacity=size // 2)
        self.reversed = List[ComplexSIMD[DType.float64, 1]](capacity=size)
        self.mags = List[SIMD[DType.float64, 1]](capacity=size // 2 + 1)
        self.phases = List[SIMD[DType.float64, 1]](capacity=size // 2 + 1)
        for _ in range(size // 2):
            self.result.append(ComplexSIMD[DType.float64, 1](0.0, 0.0))
        for _ in range(size):
            self.reversed.append(ComplexSIMD[DType.float64, 1](0.0, 0.0))
        for _ in range(size//2 + 1):
            self.mags.append(SIMD[DType.float64, 1](0.0))
            self.phases.append(SIMD[DType.float64, 1](0.0))
        self.w_ms = List[ComplexSIMD[DType.float64, 1]](capacity=self.log_n // 2)
        for i in range(self.log_n // 2):
            self.w_ms.append(ComplexSIMD[DType.float64, 1](
                Math.cos(2.0 * Math.pi / Float64(1 << (i + 1))),
                -Math.sin(2.0 * Math.pi / Float64(1 << (i + 1)))
            ))
        

        self.unpack_twiddles = List[ComplexSIMD[DType.float64, 1]](capacity=size // 2)
        for k in range(size // 2):
            var angle = -2.0 * Math.pi * Float64(k) / Float64(size)
            self.unpack_twiddles.append(ComplexSIMD[DType.float64, 1](
                Math.cos(angle), Math.sin(angle)
            ))

        self.packed_freq = List[ComplexSIMD[DType.float64, 1]](capacity=size // 2)
        for _ in range(size // 2):
            self.packed_freq.append(ComplexSIMD[DType.float64, 1](0.0, 0.0))

        self.unpacked = List[ComplexSIMD[DType.float64, 1]](capacity=size)
        for _ in range(size):
            self.unpacked.append(ComplexSIMD[DType.float64, 1](0.0, 0.0))


        self.result2 = List[ComplexSIMD[DType.float64, 2]](capacity=size // 2)
        self.reversed2 = List[ComplexSIMD[DType.float64, 2]](capacity=size)
        self.mags2 = List[SIMD[DType.float64, 2]](capacity=size // 2 + 1)
        self.phases2 = List[SIMD[DType.float64, 2]](capacity=size // 2 + 1)
        for _ in range(size // 2):
            self.result2.append(ComplexSIMD[DType.float64, 2](0.0, 0.0))
        for _ in range(size):
            self.reversed2.append(ComplexSIMD[DType.float64, 2](0.0, 0.0))
        for _ in range(size//2 + 1):
            self.mags2.append(SIMD[DType.float64, 2](0.0))
            self.phases2.append(SIMD[DType.float64, 2](0.0))
        self.w_ms2 = List[ComplexSIMD[DType.float64, 2]](capacity=self.log_n // 2)
        for i in range(self.log_n // 2):
            self.w_ms2.append(ComplexSIMD[DType.float64, 2](
                Math.cos(2.0 * Math.pi / Float64(1 << (i + 1))),
                -Math.sin(2.0 * Math.pi / Float64(1 << (i + 1)))
            ))
        

        self.unpack_twiddles2 = List[ComplexSIMD[DType.float64, 2]](capacity=size // 2)
        for k in range(size // 2):
            var angle = -2.0 * Math.pi * Float64(k) / Float64(size)
            self.unpack_twiddles2.append(ComplexSIMD[DType.float64, 2](
                Math.cos(angle), Math.sin(angle)
            ))

        self.packed_freq2 = List[ComplexSIMD[DType.float64, 2]](capacity=size // 2)
        for _ in range(size // 2):
            self.packed_freq2.append(ComplexSIMD[DType.float64, 2](0.0, 0.0))

        self.unpacked2 = List[ComplexSIMD[DType.float64, 2]](capacity=size)
        for _ in range(size):
            self.unpacked2.append(ComplexSIMD[DType.float64, 2](0.0, 0.0))

        
        self.bit_reverse_lut = List[Int](capacity=size // 2)
        for i in range(size // 2):
            self.bit_reverse_lut.append(self.bit_reverse(i, self.log_n))  # Full size

    fn bit_reverse(self,num: Int, bits: Int) -> Int:
        """Reverse the bits of a number."""
        var result = 0
        var n = num
        for _ in range(bits):
            result = (result << 1) | (n & 1)
            n >>= 1
        return result

    fn fft[num_chans: Int = 1](mut self, input: List[SIMD[DType.float64, num_chans]]):
        if num_chans == 1:
            for i in range(size // 2):
                var real_part = input[2 * i][0]
                var imag_part = input[2 * i + 1][0]
                self.result[self.bit_reverse_lut[i]] = ComplexSIMD[DType.float64, 1](real_part, imag_part)

            for stage in range(1, self.log_n + 1):
                var m = 1 << stage
                var half_m = m >> 1
                
                stage_twiddle = ComplexSIMD[DType.float64, 1](
                    Math.cos(2.0 * Math.pi / Float64(m)),
                    -Math.sin(2.0 * Math.pi / Float64(m))
                )

                for k in range(0, size // 2, m):
                    var w = ComplexSIMD[DType.float64, 1](1.0, 0.0)
                    
                    for j in range(half_m):
                        var idx1 = k + j
                        var idx2 = k + j + half_m
                        
                        var t = w * self.result[idx2]
                        var u = self.result[idx1]
                        
                        self.result[idx1] = u + t
                        self.result[idx2] = u - t

                        w = w * stage_twiddle

            for k in range(size // 2 + 1):
                if k == 0:
                    # DC components
                    var X_even_0 = (self.result[0].re + self.result[0].re) * 0.5  # Real part
                    var X_odd_0 = (self.result[0].im + self.result[0].im) * 0.5   # Imag part
                    self.unpacked[0] = ComplexSIMD[DType.float64, 1](X_even_0 + X_odd_0, SIMD[DType.float64, 1](0.0))
                    if size > 1:
                        self.unpacked[size // 2] = ComplexSIMD[DType.float64, 1](X_even_0 - X_odd_0, SIMD[DType.float64, 1](0.0))
                elif k < size // 2:
                    var Gk = self.result[k]
                    var Gk_conj = self.result[size // 2 - k].conj()
                    
                    var X_even_k = (Gk + Gk_conj) * 0.5
                    var X_odd_k = (Gk - Gk_conj) * ComplexSIMD[DType.float64, 1](0.0, -0.5)
                    
                    var twiddle = self.unpack_twiddles[k]
                    var X_odd_k_rotated = X_odd_k * twiddle
                    
                    self.unpacked[k] = X_even_k + X_odd_k_rotated
                    self.unpacked[size - k] = (X_even_k - X_odd_k_rotated).conj()

            self.result.clear()
            self.result.resize(size, ComplexSIMD[DType.float64, 1](0.0, 0.0))
            for i in range(size):
                self.result[i] = self.unpacked[i]

            # Compute magnitudes and phases
            for i in range(size // 2 + 1):
                self.mags[i] = self.result[i].norm()
                self.phases[i] = Math.atan2(self.result[i].im, self.result[i].re)
        elif num_chans == 2:
            for i in range(size // 2):
                var real_part = SIMD[DType.float64, 2](input[2 * i][0], input[2 * i][1])
                var imag_part = SIMD[DType.float64, 2](input[2 * i + 1][0], input[2 * i + 1][1])
                self.result2[self.bit_reverse_lut[i]] = ComplexSIMD[DType.float64, 2](real_part, imag_part)

            for stage in range(1, self.log_n + 1):
                var m = 1 << stage
                var half_m = m >> 1
                
                var stage_twiddle = ComplexSIMD[DType.float64, 2](
                    Math.cos(2.0 * Math.pi / Float64(m)),
                    -Math.sin(2.0 * Math.pi / Float64(m))
                )

                for k in range(0, size // 2, m):
                    var w = ComplexSIMD[DType.float64, 2](1.0, 0.0)
                    
                    for j in range(half_m):
                        var idx1 = k + j
                        var idx2 = k + j + half_m
                        
                        var t = w * self.result2[idx2]
                        var u = self.result2[idx1]
                        
                        self.result2[idx1] = u + t
                        self.result2[idx2] = u - t
                        w = w * stage_twiddle

            for k in range(size // 2 + 1):
                if k == 0:
                    # DC components
                    var X_even_0 = (self.result2[0].re + self.result2[0].re) * 0.5  # Real part
                    var X_odd_0 = (self.result2[0].im + self.result2[0].im) * 0.5   # Imag part
                    self.unpacked2[0] = ComplexSIMD[DType.float64, 2](
                        X_even_0 + X_odd_0,          
                        SIMD[DType.float64, 2](0.0, 0.0)  
                    )
                    if size > 1:
                        self.unpacked2[size // 2] = ComplexSIMD[DType.float64, 2](X_even_0 - X_odd_0, SIMD[DType.float64, 2](0.0))
                elif k < size // 2:
                    var Gk = self.result2[k]
                    var Gk_conj = self.result2[size // 2 - k].conj()

                    var X_even_k = (Gk + Gk_conj) * 0.5
                    var X_odd_k = (Gk - Gk_conj) * ComplexSIMD[DType.float64, 2](0.0, -0.5)

                    var twiddle = self.unpack_twiddles2[k]
                    var X_odd_k_rotated = X_odd_k * twiddle

                    self.unpacked2[k] = X_even_k + X_odd_k_rotated
                    self.unpacked2[size - k] = (X_even_k - X_odd_k_rotated).conj()

            self.result2.clear()
            self.result2.resize(size, ComplexSIMD[DType.float64, 2](0.0, 0.0))
            for i in range(size):
                self.result2[i] = self.unpacked2[i]

            # Compute magnitudes and phases
            for i in range(size // 2 + 1):
                self.mags2[i] = self.result2[i].norm()
                self.phases2[i] = Math.atan2(self.result2[i].im, self.result2[i].re)
        
    fn ifft[num_chans: Int = 1](mut self, mut output: List[SIMD[DType.float64, num_chans]]):
        # full inverse FFT

        if num_chans == 1:
        
            for k in range(size // 2 + 1):
                if k < len(self.mags):
                    var mag = self.mags[k]
                    var phase = self.phases[k]
                    
                    var real_part = mag * Math.cos(phase)
                    var imag_part = mag * Math.sin(phase)
                    
                    self.result[k] = ComplexSIMD[DType.float64, 1](real_part, imag_part)
            
            for k in range(1, size // 2):  # k=1 to size//2-1
                self.result[size - k] = self.result[k].conj()

            self.result[0] = ComplexSIMD[DType.float64, 1](self.result[0].re, SIMD[DType.float64, 1](0.0))
            self.result[size // 2] = ComplexSIMD[DType.float64, 1](self.result[size // 2].re, SIMD[DType.float64, 1](0.0))
            
            #  this should be a variable, but it won't let me make it one!
            for i in range(size):
                self.reversed[self.bit_reverse(i, self.log_n_full)] = self.result[i]

            for stage in range(1, self.log_n_full + 1):
                var m = 1 << stage
                var half_m = m >> 1
                
                var stage_twiddle = ComplexSIMD[DType.float64, 1](
                    Math.cos(2.0 * Math.pi / Float64(m)),
                    Math.sin(2.0 * Math.pi / Float64(m))
                )
                
                for k in range(0, size, m):
                    var w = ComplexSIMD[DType.float64, 1](1.0, 0.0)
                    
                    for j in range(half_m):
                        var idx1 = k + j
                        var idx2 = k + j + half_m

                        var t = w * self.reversed[idx2]
                        var u = self.reversed[idx1]

                        self.reversed[idx1] = u + t
                        self.reversed[idx2] = u - t
                        w = w * stage_twiddle
            
            # Extract real parts
            for i in range(min(size, len(output))):
                output[i] = self.reversed[i].re * self.scale

        elif num_chans == 2:
            for k in range(size // 2 + 1):
                if k < len(self.mags2):
                    var mag = self.mags2[k]
                    var phase = self.phases2[k]

                    var real_part = mag * Math.cos(phase)
                    var imag_part = mag * Math.sin(phase)
                    
                    self.result2[k] = ComplexSIMD[DType.float64, 2](real_part, imag_part)
            
            for k in range(1, size // 2):  # k=1 to size//2-1
                self.result2[size - k] = self.result2[k].conj()

            self.result2[0] = ComplexSIMD[DType.float64, 2](self.result2[0].re, SIMD[DType.float64, 2](0.0))
            self.result2[size // 2] = ComplexSIMD[DType.float64, 2](self.result2[size // 2].re, SIMD[DType.float64, 2](0.0))

            for i in range(size):
                self.reversed2[self.bit_reverse(i, self.log_n_full)] = self.result2[i]

            for stage in range(1, self.log_n_full + 1):
                var m = 1 << stage
                var half_m = m >> 1
                
                var stage_twiddle = ComplexSIMD[DType.float64, 2](
                    Math.cos(2.0 * Math.pi / Float64(m)),
                    Math.sin(2.0 * Math.pi / Float64(m))
                )
                
                for k in range(0, size, m):
                    var w = ComplexSIMD[DType.float64, 2](1.0, 0.0)
                    
                    for j in range(half_m):
                        var idx1 = k + j
                        var idx2 = k + j + half_m

                        var t = w * self.reversed2[idx2]
                        var u = self.reversed2[idx1]

                        self.reversed2[idx1] = u + t
                        self.reversed2[idx2] = u - t
                        w = w * stage_twiddle
            
            # Extract real parts
            for i in range(min(size, len(output))):
                output[i] = SIMD[DType.float64, num_chans](self.reversed2[i].re[0], self.reversed2[i].re[1]) * self.scale