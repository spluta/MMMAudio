"""
A synthesis example that sends Dust, single sample triggers to a resonant band-pass filter.

Rates of the Dusts and frequencies of the filters are modulated by the mouse X and Y positions.
"""

from srcpy import * 

# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="OleDusty", package_name="examples")
src_mojo.start_audio() 

src_mojo.stop_audio()

src_mojo.plot(48000)