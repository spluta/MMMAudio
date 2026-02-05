# Test the Euler ODE solver with a simple RC low-pass filter.
# Should produce a smooth filtered noise signal.

from mmm_python.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestODEFilter", package_name="examples.tests")
mmm_audio.start_audio() 


mmm_audio.stop_audio()