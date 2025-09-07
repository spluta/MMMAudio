# # """
# # This outputs something, but it isn't right!

# # A translation of Miller Puckette's Mayer FFT implementation from Sigmund, etc.

# # In respect of the author's wishes, we thank Euler, Gauss, Hartley, Buneman, Mayer, and Puckette.

# # This should probably get replaced by an FFTW or RustFFT interface.
# # """
# from python import PythonObject
# from python.bindings import PythonModuleBuilder

# from math import log2, pi, exp, cos, sin, sqrt
# from memory import memset_zero
# from algorithm import vectorize
# import math

# struct Complex64:
#     var real: Float64
#     var imag: Float64
    
#     fn __init__(out self, real: Float64 = 0.0, imag: Float64 = 0.0):
#         self.real = real
#         self.imag = imag
    
#     fn __add__(self, other: Self) -> Self:
#         return Complex64(self.real + other.real, self.imag + other.imag)
    
#     fn __sub__(self, other: Self) -> Self:
#         return Complex64(self.real - other.real, self.imag - other.imag)
    
#     fn __mul__(self, other: Self) -> Self:
#         return Complex64(
#             self.real * other.real - self.imag * other.imag,
#             self.real * other.imag + self.imag * other.real
#         )
    
#     fn __mul__(self, scalar: Float64) -> Self:
#         return Complex64(self.real * scalar, self.imag * scalar)

# fn is_power_of_2(n: Int) -> Bool:
#     """Check if n is a power of 2"""
#     return n > 0 and (n & (n - 1)) == 0

# fn exp_complex(theta: Float64) -> Complex64:
#     """Compute e^(i*theta) = cos(theta) + i*sin(theta)"""
#     return Complex64(cos(theta), sin(theta))

# fn FFT_vectorized(x: List[Float64]) raises -> List[Complex64]:
#     """A vectorized, non-recursive version of the Cooley-Tukey FFT"""
#     var N = len(x)
    
#     if not is_power_of_2(N):
#         raise Error("size of x must be a power of 2")
    
#     # N_min here is equivalent to the stopping condition above,
#     # and should be a power of 2
#     var N_min = min(N, 32)
    
#     # Perform an O[N^2] DFT on all length-N_min sub-problems at once
#     var num_blocks = N // N_min
#     var X = List[Complex64](capacity=N)
    
#     # Initialize X with zeros
#     for i in range(N):
#         X.append(Complex64(0.0, 0.0))
    
#     # Compute DFT for each block
#     for block in range(num_blocks):
#         for k in range(N_min):
#             var sum_val = Complex64(0.0, 0.0)
#             for n in range(N_min):
#                 var angle = -2.0 * pi * Float64(n * k) / Float64(N_min)
#                 var twiddle = exp_complex(angle)
#                 var x_idx = block * N_min + n
#                 sum_val = sum_val + twiddle * x[x_idx]
#             X[k * num_blocks + block] = sum_val
    
#     # Build-up each level of the recursive calculation
#     var current_size = N_min
#     var current_blocks = num_blocks
    
#     while current_size < N:
#         var new_X = List[Complex64](capacity=N)
#         for i in range(N):
#             new_X.append(Complex64(0.0, 0.0))
        
#         var half_blocks = current_blocks // 2
        
#         # Process even and odd parts
#         for k in range(current_size):
#             var factor_angle = -pi * Float64(k) / Float64(current_size)
#             var factor = exp_complex(factor_angle)
            
#             for block in range(half_blocks):
#                 var even_idx = k * current_blocks + block
#                 var odd_idx = k * current_blocks + block + half_blocks
                
#                 var X_even = X[even_idx]
#                 var X_odd = X[odd_idx]
                
#                 # Combine even and odd parts
#                 var new_idx_1 = k * half_blocks + block
#                 var new_idx_2 = (k + current_size) * half_blocks + block
                
#                 new_X[new_idx_1] = X_even + factor * X_odd
#                 new_X[new_idx_2] = X_even - factor * X_odd
        
#         X = new_X^  # Move ownership
#         current_size *= 2
#         current_blocks = half_blocks
    
#     # Ravel (flatten) the result - in this case it's already flat
#     var result = List[Complex64](capacity=N)
#     for i in range(N):
#         result.append(X[i])
    
#     return result^

# # Helper function for real input
# fn FFT_vectorized_real(x: List[Float64]) raises -> List[Complex64]:
#     """FFT for real input, returns complex output"""
#     return FFT_vectorized(x)

# # Alternative version with SIMD optimization for the DFT computation
# fn FFT_vectorized_simd(x: List[Float64]) raises -> List[Complex64]:
#     """SIMD-optimized version of the vectorized FFT"""
#     var N = len(x)
    
#     if not is_power_of_2(N):
#         raise Error("size of x must be a power of 2")
    
#     var N_min = min(N, 32)
#     var num_blocks = N // N_min
#     var X = List[Complex64](capacity=N)
    
#     # Initialize X
#     for i in range(N):
#         X.append(Complex64(0.0, 0.0))
    
#     # Vectorized DFT computation
#     alias simd_width = 4  # Adjust based on your target architecture
    
#     for block in range(num_blocks):
#         for k in range(N_min):
#             var sum_real: Float64 = 0.0
#             var sum_imag: Float64 = 0.0
            
#             @parameter
#             fn compute_dft_element[width: Int](n: Int):
#                 if n < N_min:
#                     var angle = -2.0 * pi * Float64(n * k) / Float64(N_min)
#                     var cos_val = cos(angle)
#                     var sin_val = sin(angle)
#                     var x_val = x[block * N_min + n]
#                     sum_real += cos_val * x_val
#                     sum_imag += sin_val * x_val
            
#             vectorize[compute_dft_element, simd_width](N_min)
#             X[k * num_blocks + block] = Complex64(sum_real, sum_imag)
    
#     # Build-up phase (same as non-SIMD version)
#     var current_size = N_min
#     var current_blocks = num_blocks
    
#     while current_size < N:
#         var new_X = List[Complex64](capacity=N)
#         for i in range(N):
#             new_X.append(Complex64(0.0, 0.0))
        
#         var half_blocks = current_blocks // 2
        
#         for k in range(current_size):
#             var factor_angle = -pi * Float64(k) / Float64(current_size)
#             var factor = exp_complex(factor_angle)
            
#             for block in range(half_blocks):
#                 var even_idx = k * current_blocks + block
#                 var odd_idx = k * current_blocks + block + half_blocks
                
#                 var X_even = X[even_idx]
#                 var X_odd = X[odd_idx]
                
#                 var new_idx_1 = k * half_blocks + block
#                 var new_idx_2 = (k + current_size) * half_blocks + block
                
#                 new_X[new_idx_1] = X_even + factor * X_odd
#                 new_X[new_idx_2] = X_even - factor * X_odd
        
#         X = new_X^
#         current_size *= 2
#         current_blocks = half_blocks
    
#     return X^

# # Example usage function
# fn test_fft():
#     try:
#         # Create test signal
#         var x = List[Float64]()
#         var N = 8
        
#         # Simple impulse
#         for i in range(N):
#             if i == 0:
#                 x.append(1.0)
#             else:
#                 x.append(0.0)
        
#         var result = FFT_vectorized(x)
        
#         print("FFT Result:")
#         for i in range(len(result)):
#             print("X[", i, "] = ", result[i].real, " + ", result[i].imag, "j")
            
#     except e:
#         print("Error:", e)

#     fn ifft(mut self, mut real: List[Float64], mut imag: List[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])
#         ptr_imag: UnsafePointer[Float64] = UnsafePointer(to=imag[0])

#         n = len(real)

#         self.ifft(n, ptr, ptr_imag)

#     fn rfft(mut self, n: Int, mut real: UnsafePointer[Float64]):
#         """Real-valued Fast Fourier Transform."""
#         print(n)

#         self.fht(real, n)

#         var k = n // 2
#         for i in range(1, k):
#             var j = n - 1 - i
#             var a = real[i]
#             var b = real[j]
#             real[j] = (a - b) * 0.5
#             real[i] = (a + b) * 0.5

#     fn rfft_s(mut self, n: Int, mut real: UnsafePointer[Float64]):
#         """Real-valued Fast Fourier Transform (single precision)."""
#         print(n)

#         self.fht(real, n)

#         var k = n // 2
#         alias simd_width = simdwidthof[Float64]()
    
#         @parameter
#         fn vectorized_transform[simd_width: Int](idx: Int):
#             var i = idx + 1  # Start from index 1
#             if i < k:
#                 var j = n - 1 - i
#                 var a = real[i]
#                 var b = real[j]
#                 real[j] = (a - b) * 0.5
#                 real[i] = (a + b) * 0.5
        
#         vectorize[vectorized_transform, 1](k - 1)  # Process k-1 elements (indices 1 to k-1)

#     fn rfft(mut self, mut real: List[Float64]):
#         """Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])

#         n = len(real)
#         self.rfft(n, ptr)

#     fn irfft(mut self, n: Int, mut real: UnsafePointer[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         var k = n // 2
#         for i in range(1, k):
#             var j = n - 1 - i
#             var a = real[i]
#             var b = real[j]
#             real[j] = a - b
#             real[i] = a + b
        
#         self.fht(real, n)

#     fn irfft(mut self, mut real: List[Float64]):
#         """Inverse Real-valued Fast Fourier Transform."""
#         ptr: UnsafePointer[Float64] = UnsafePointer(to=real[0])

#         n = len(real)
#         self.irfft(n, ptr)

#     @staticmethod
#     fn py_rfft(py_self: UnsafePointer[Self], args: PythonObject) raises -> PythonObject:
#         """Fast Fourier Transform."""
#         length = len(args)

#         var pointer = args.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()
#         py_self[0].rfft(length, pointer)

#         return PythonObject(None)

# @export
# fn PyInit_MMM_FFT() -> PythonObject:
#     """Python initialization function for MMM_FFT."""
#     try:
#         var mb = PythonModuleBuilder("MMM_FFT")

#         _ = (
#             mb.add_type[MMM_FFT]("MMM_FFT")
#             .def_py_init[MMM_FFT.py_init]()
#             # .def_method[MMM_FFT.py_fft]("fft")
#             # .def_method[MMM_FFT.ifft]("ifft")
#             .def_method[MMM_FFT.py_rfft]("py_rfft")
#             # .def_method[MMM_FFT.irfft]("irfft")
#         )

#         return mb.finalize()
#     except Exception:
#         print("Error initializing MMM_FFT")
#         return None