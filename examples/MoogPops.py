"""
A synthesis example that sends Dust, single sample triggers to a Virtual Analog Moog-style ladder filter. The ladder filter uses oversampling that allows for more extreme resonance settings without comptimeing artifacts.
"""


from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="MoogPops", package_name="examples")
mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.stop_audio() # stop the audio thread
mmm_audio.plot(10000)