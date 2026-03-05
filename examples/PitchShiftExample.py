"""
Demonstrates how to use the PitchShift grain-based pitch shifter with microphone input.

This example assumes you have a microphone input device set up and selected as the default input device on your system.

A couple of settings in the .py file are important: 

- num_input_channels: This can be set to any value, but it should be at least as high as the input channel you want to use.
- in_chan: This should be set to the input channel number of your microphone input source (0-indexed).

The graph allows you to set various parameters for the pitch shifter:

- which_input: Selects which input channel to use from the multi-channel input (0-indexed).
- pitch_shift: Sets the pitch shift factor (e.g., 1.0 = no shift, 2.0 = one octave up, 0.5 = one octave down).
- grain_dur: Sets the duration of the grains in seconds.
- pitch_dispersion: Sets the amount of random variation in pitch for each grain.
- time_dispersion: Sets the amount of random variation in timing for each grain.
"""

from mmm_python import *
mmm_audio = MMMAudio(128, num_input_channels = 12, graph_name="PitchShiftExample", package_name="examples")
mmm_audio.send_int("in_chan", 0) # set input channel to your input source
mmm_audio.start_audio() # start the audio thread - or restart it where it left off


mmm_audio.send_float("which_input", 2)
mmm_audio.send_float("pitch_shift", 1.5)
mmm_audio.send_float("grain_dur", 0.4)

mmm_audio.send_float("pitch_dispersion", 0.4)

mmm_audio.send_float("time_dispersion", 0.5)

mmm_audio.send_float("pitch_dispersion", 0.0)
mmm_audio.send_float("time_dispersion", 0.0)

mmm_audio.start_audio()
mmm_audio.stop_audio()  # stop the audio thread

mmm_audio.plot(44000)