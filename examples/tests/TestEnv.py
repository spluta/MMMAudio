from mmm_python import *


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestEnv", package_name="examples.tests")
# mmm_audio.start_audio() 

mmm_audio.plot(48000)

mmm_audio.send_float("mul", 0.5)

mmm_audio.start_audio()

mmm_audio.stop_audio() 