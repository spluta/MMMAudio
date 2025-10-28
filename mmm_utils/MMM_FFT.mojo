# fn rfft[
#     dtype: DType = DType.float64
# ](arr: NDArray[dtype]) raises -> ComplexNDArray[ComplexDType.from_dtype(dtype)]:
#     """Optimized Real FFT that processes real data more efficiently.
    
#     This version uses the fact that we can pack two real sequences into
#     one complex sequence and use properties of the DFT to extract both
#     transforms efficiently.
#     """
#     if arr.ndim != 1:
#         raise Error("Real FFT currently only supports 1D arrays")

#     var n: Int = arr.shape[0]
#     if n <= 1:
#         var result_shape = NDArrayShape(1)
#         var result = ComplexNDArray[ComplexDType.from_dtype(dtype)](result_shape)
#         if n == 1:
#             result[Item(0)] = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#                 arr[Item(0)].cast[dtype](), 0.0
#             )
#         return result

#     if (n & (n - 1)) != 0:
#         raise Error(
#             "Real FFT currently only supports arrays with length that is a power of 2"
#         )

#     # For even-length sequences, we can use a more efficient approach
#     # by treating pairs of real samples as complex numbers
#     var half_n = n // 2
#     var packed_input = ComplexNDArray[ComplexDType.from_dtype(dtype)](NDArrayShape(half_n))
    
#     # Pack pairs of real samples into complex numbers
#     for i in range(half_n):
#         packed_input[Item(i)] = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#             arr[Item(2 * i)].cast[dtype](),     # Real part: even samples
#             arr[Item(2 * i + 1)].cast[dtype]() # Imag part: odd samples
#         )

#     # Perform FFT on packed data
#     var packed_fft = _fft_complex[ComplexDType.from_dtype(dtype)](packed_input)

#     # Unpack the result using symmetry properties
#     var output_size = n // 2 + 1
#     var result = ComplexNDArray[ComplexDType.from_dtype(dtype)](NDArrayShape(output_size))

#     # DC component
#     result[Item(0)] = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#         packed_fft[Item(0)].re + packed_fft[Item(0)].im, 0.0
#     )

#     # Other components require twiddle factor corrections
#     for k in range(1, half_n):
#         var fk = packed_fft[Item(k)]
#         var fmk = packed_fft[Item(half_n - k)].conjugate()
        
#         var angle = Constants.pi * Scalar[dtype](k) / Scalar[dtype](n)
#         var w = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#             cos(angle).cast[dtype](), -sin(angle).cast[dtype]()
#         )
        
#         var a = (fk + fmk) * 0.5
#         var b = (fk - fmk) * ComplexSIMD[ComplexDType.from_dtype(dtype)](0.0, -0.5)
        
#         result[Item(k)] = a + w * b

#     # Nyquist component (if it exists)
#     if output_size > half_n:
#         result[Item(half_n)] = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#             packed_fft[Item(0)].re - packed_fft[Item(0)].im, 0.0
#         )

#     return result^

# fn irfft[
#     dtype: DType = DType.float64
# ](arr: ComplexNDArray[ComplexDType.from_dtype(dtype)], n: Optional[Int] = None) raises -> NDArray[dtype]:
#     """Computes the Inverse Real Fast Fourier Transform using the Cooley-Tukey algorithm.

#     The inverse real FFT takes a complex frequency domain representation (typically
#     from an RFFT) and returns the real time domain signal. The input should have
#     conjugate symmetry properties to produce a real output.

#     Parameters:
#         dtype: The data type of the real output elements (DType).

#     Args:
#         arr: Input complex array representing frequency domain coefficients.
#              Must be 1-dimensional with length N//2 + 1 where N is the desired
#              output length.
#         n: Optional output length. If not specified, computed as 2*(len(arr)-1).

#     Returns:
#         NDArray containing the real inverse FFT. Output length is n.

#     Raises:
#         Error: If the input array is not 1-dimensional.
#         Error: If the computed length is not a power of 2.

#     Example:
#         ```mojo
#         import scijo as sj
#         import numojo as nm
#         var freq_data = nm.zeros[nm.cf32](nm.Shape(5))  # For 8-point real signal
#         var time_signal = sj.fft.irfft[nm.f32](freq_data)
#         ```

#     Note:
#         The input array should have conjugate symmetry. Only the first N//2 + 1
#         coefficients are needed due to this symmetry property.
#     """
#     if arr.ndim != 1:
#         raise Error("Real IFFT currently only supports 1D arrays")

#     var input_len = arr.shape[0]
#     var output_len: Int
    
#     if n:
#         output_len = n.value()
#     else:
#         output_len = 2 * (input_len - 1)

#     if output_len <= 0:
#         raise Error("Output length must be positive")

#     if (output_len & (output_len - 1)) != 0:
#         raise Error(
#             "Real IFFT currently only supports output lengths that are powers of 2"
#         )

#     # Reconstruct the full complex spectrum using conjugate symmetry
#     var full_spectrum = ComplexNDArray[ComplexDType.from_dtype(dtype)](NDArrayShape(output_len))
    
#     # Copy the positive frequencies
#     for i in range(input_len):
#         full_spectrum[Item(i)] = arr[Item(i)]
    
#     # Fill in the negative frequencies using conjugate symmetry: X[N-k] = X*[k]
#     for i in range(1, input_len - 1):  # Skip DC (i=0) and Nyquist (if present)
#         var conj_idx = output_len - i
#         full_spectrum[Item(conj_idx)] = arr[Item(i)].conjugate()

#     # Perform inverse FFT on the full spectrum
#     var complex_result = ifft[ComplexDType.from_dtype(dtype)](full_spectrum)
    
#     # Extract real part (imaginary part should be ~0 for real signals)
#     var result = NDArray[dtype](NDArrayShape(output_len))
#     for i in range(output_len):
#         result[Item(i)] = complex_result[Item(i)].re.cast[dtype]()

#     return result^

# fn irfft_optimized[
#     dtype: DType = DType.float64
# ](arr: ComplexNDArray[ComplexDType.from_dtype(dtype)], n: Optional[Int] = None) raises -> NDArray[dtype]:
#     """Optimized Inverse Real FFT that avoids full spectrum reconstruction.
    
#     This version uses more efficient algorithms that work directly with the
#     half-spectrum representation, avoiding the memory overhead of reconstructing
#     the full conjugate-symmetric spectrum.
#     """
#     if arr.ndim != 1:
#         raise Error("Real IFFT currently only supports 1D arrays")

#     var input_len = arr.shape[0]
#     var output_len: Int
    
#     if n:
#         output_len = n.value()
#     else:
#         output_len = 2 * (input_len - 1)

#     if output_len <= 0:
#         raise Error("Output length must be positive")

#     if (output_len & (output_len - 1)) != 0:
#         raise Error(
#             "Real IFFT currently only supports output lengths that are powers of 2"
#         )

#     # Handle small cases directly
#     if output_len <= 2:
#         var result = NDArray[dtype](NDArrayShape(output_len))
#         if output_len == 1:
#             result[Item(0)] = arr[Item(0)].re.cast[dtype]()
#         elif output_len == 2:
#             result[Item(0)] = arr[Item(0)].re.cast[dtype]()
#             result[Item(1)] = arr[Item(1)].re.cast[dtype]()
#         return result

#     # For larger sizes, use the reverse of the optimized RFFT approach
#     var half_n = output_len // 2
    
#     # Prepare data for inverse transform
#     var packed_data = ComplexNDArray[ComplexDType.from_dtype(dtype)](NDArrayShape(half_n))
    
#     # Handle DC component
#     var dc_real = arr[Item(0)].re
#     var nyquist_real = 0.0
#     if input_len > half_n:
#         nyquist_real = arr[Item(half_n)].re
    
#     packed_data[Item(0)] = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#         (dc_real + nyquist_real) * 0.5, (dc_real - nyquist_real) * 0.5
#     )

#     # Process other frequency bins
#     for k in range(1, half_n):
#         var fk = arr[Item(k)]
#         var angle = Constants.pi * Scalar[dtype](k) / Scalar[dtype](output_len)
#         var w = ComplexSIMD[ComplexDType.from_dtype(dtype)](
#             cos(angle).cast[dtype](), sin(angle).cast[dtype]()
#         )
        
#         # Reverse the packing process from optimized RFFT
#         var fmk = arr[Item(k)].conjugate()  # This would be the conjugate symmetric part
        
#         var a = fk + fmk
#         var b = (fk - fmk) * ComplexSIMD[ComplexDType.from_dtype(dtype)](0.0, 1.0) / w
        
#         packed_data[Item(k)] = (a + b) * 0.5

#     # Perform inverse FFT on packed data
#     var packed_ifft = ifft[ComplexDType.from_dtype(dtype)](packed_data)
    
#     # Unpack the result
#     var result = NDArray[dtype](NDArrayShape(output_len))
#     for i in range(half_n):
#         result[Item(2 * i)] = packed_ifft[Item(i)].re.cast[dtype]()      # Even samples
#         result[Item(2 * i + 1)] = packed_ifft[Item(i)].im.cast[dtype]()  # Odd samples

#     return result^

# # Helper function for unnormalized inverse real FFT
# fn _irfft_unnormalized[
#     dtype: DType = DType.float64
# ](arr: ComplexNDArray[ComplexDType.from_dtype(dtype)], output_len: Int) raises -> NDArray[dtype]:
#     """Internal unnormalized inverse real FFT helper function."""
#     # Reconstruct full spectrum
#     var full_spectrum = ComplexNDArray[ComplexDType.from_dtype(dtype)](NDArrayShape(output_len))
#     var input_len = arr.shape[0]
    
#     # Copy positive frequencies
#     for i in range(input_len):
#         full_spectrum[Item(i)] = arr[Item(i)]
    
#     # Add conjugate symmetric negative frequencies
#     for i in range(1, input_len - 1):
#         var conj_idx = output_len - i
#         full_spectrum[Item(conj_idx)] = arr[Item(i)].conjugate()

#     # Use the existing unnormalized IFFT but don't normalize
#     var complex_result = _ifft_unnormalized[ComplexDType.from_dtype(dtype)](full_spectrum)
    
#     # Extract real part and apply normalization
#     var result = NDArray[dtype](NDArrayShape(output_len))
#     var inv_n = 1.0 / Scalar[dtype](output_len)
    
#     for i in range(output_len):
#         result[Item(i)] = (complex_result[Item(i)].re * inv_n).cast[dtype]()

#     return result^