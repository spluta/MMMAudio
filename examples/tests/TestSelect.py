from mmm_python import *


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestSelect", package_name="examples.tests")
mmm_audio.start_audio() 

mmm_audio.send_float("which", 1.5)
mmm_audio.send_floats("vs", [11,13,15,17,19])
mmm_audio.send_float("which", 0.59)

mmm_audio.stop_audio()