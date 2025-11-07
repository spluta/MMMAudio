from mmm_src.MMMWorld import *
from complex import ComplexFloat64

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
