from srcpy import *


# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestSelect", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.send_float("which", 1.5)
src_mojo.send_floats("vs", [11,13,15,17,19])
src_mojo.send_float("which", 0.59)

src_mojo.stop_audio()