FFTProcess is similar to BufferedProcess, but instead of passing time domain samples to the user defined struct,
it passes frequency domain magnitudes and phases (obtained from an FFT). The user defined struct must implement
the FFTProcessable trait, which requires the implementation of the `.next_frame()` function. This function
receives two Lists: one for magnitudes and one for phases. The user can do whatever they want with the values in these Lists,
and then must replace the values in the Lists with the values they want to be used for the IFFT to convert the information
back to amplitude samples.