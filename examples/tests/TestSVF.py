from mmmaudio import *


# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestSVF", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.send_float("freq", 40.0)
src_mojo.send_float("cutoff", 100.0)
src_mojo.send_float("res", 8.0)

src_mojo.stop_audio()