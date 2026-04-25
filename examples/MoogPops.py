"""
A synthesis example that sends Dust, single sample triggers to a Virtual Analog Moog-style ladder filter. The ladder filter uses oversampling that allows for more extreme resonance settings without comptimeing artifacts.
"""


from mmmaudio import *
src_mojo = MMMAudio(128, graph_name="MoogPops", package_name="examples")
src_mojo.start_audio() # start the audio thread - or restart it where it left off

src_mojo.stop_audio() # stop the audio thread
src_mojo.plot(10000)