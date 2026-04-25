from mmmaudio import *

src_mojo = MMMAudio(128, graph_name="TestBufferedProcess", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.send_float("factor",2478.0)
src_mojo.stop_audio()