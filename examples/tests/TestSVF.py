from mmm_python import *


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestSVF", package_name="examples.tests")
mmm_audio.start_audio() 

mmm_audio.send_float("freq", 40.0)
mmm_audio.send_float("cutoff", 100.0)
mmm_audio.send_float("res", 8.0)

mmm_audio.stop_audio()