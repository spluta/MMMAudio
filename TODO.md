FIX

- Mojo seems to be trying to free the numpy array inside of InterleavedBuffer without consent. I added a print statement in Grains.mojo to avoid this for now, but it's not a real fix.

Documentation

- make .md files for each of the structs in the codebase

FFT

- we need it

UGens

- Amplitude
- Freeverb, Dattoro, GVerb

Big Ones

- replace pyaudio with Mojo PortAudio bindings
- load and save wav files without numpy/scipy
- Multiple graphs in one MMM instance
- multiprocessor support