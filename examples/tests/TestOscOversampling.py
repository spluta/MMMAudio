from mmmaudio import *

# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestOscOversampling", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.send_float("which", 0.0) # none
src_mojo.send_float("which", 1.0) # 2x
src_mojo.send_float("which", 2.0) # 4x
src_mojo.send_float("which", 3.0) # 8x
src_mojo.send_float("which", 4.0) # 16x

src_mojo.stop_audio()  