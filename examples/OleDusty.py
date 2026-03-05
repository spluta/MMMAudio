"""
A synthesis example that sends Dust, single sample triggers to a resonant band-pass filter.

Rates of the Dusts and frequencies of the filters are modulated by the mouse X and Y positions.
"""

from mmm_python import * 

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="OleDusty", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.stop_audio()

mmm_audio.plot(48000)