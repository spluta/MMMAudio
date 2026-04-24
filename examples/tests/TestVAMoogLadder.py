from srcpy import *

# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestVAMoogLadder", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.send_float("which", 0.0)
src_mojo.send_float("which", 1.0)
src_mojo.send_float("which", 2.0) # 16x oversampling self oscillates much better


src_mojo.stop_audio()