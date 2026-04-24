The Mel scale is a perceptual scale of pitches that approximates the human ear's response more closely than the linear frequency scale. Mel Bands analysis involves mapping the FFT frequency bins to the Mel scale and computing the energy in each Mel band. This way the "magnitudes" of each Mel band represent a, roughly, equal amount of perceptual frequency space (unlike the FFT).

Because the definition of the mel scale is conditioned by a finite number
of subjective psychoacoustical experiments, several implementations coexist
in the audio signal processing literature. MMMAudio replicates the default of Librosa, which replicates
the behavior of the well-established MATLAB ["Auditory Toolbox"](https://engineering.purdue.edu/~malcolm/interval/1998-010/) of Slaney (citation below).
According to this implementation,  the conversion from Hertz to mel is
linear below 1 kHz and logarithmic above 1 kHz. Additionally, the weights are normalized such that the area under each mel filter is equal. Slaney mel filter "triangles" all have equal area ([visualization](https://www.youtube.com/watch?v=UCLlVAj0PPY)), which helps to ensure that the energy in each mel band is comparable.

Slaney, M. Auditory Toolbox: A MATLAB Toolbox for Auditory Modeling Work. Technical Report, version 2, Interval Research Corporation, 1998.