"""
this example shows how to use the variable wavetable oscillator. 
it shows how the oscillator can be made using linear, quadratic, or sinc interpolation and can also be set to use oversampling. with sinc interpolation, use an oversampling index of 0 (no oversampling), 1 (2x). with linear or quadratic interpolation, use an oversampling index of 0 (no oversampling), 1 (2x), 2 (4x), 3 (8x), or 4 (16x).
"""
from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="BuchlaWaveFolder", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.stop_audio()

mmm_audio.plot(4000)


xq