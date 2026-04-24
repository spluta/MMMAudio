from srcpy import *


# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestEnv", package_name="examples.tests")
# mmm_audio.start_audio() 

src_mojo.plot(48000)

src_mojo.send_float("mul", 0.5)

src_mojo.start_audio()

src_mojo.stop_audio() 