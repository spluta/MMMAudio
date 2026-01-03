"""Buchla Wavefolder example."""

from mmm_python.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="BuchlaWaveFolder_AD", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.stop_audio()

mmm_audio.plot(4000)