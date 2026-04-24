from srcpy import *

src_mojo = MMMAudio(128, graph_name="TestRMS", package_name="examples.tests")
src_mojo.start_audio() 
src_mojo.send_float("vol",-12.0)
src_mojo.send_float("vol",0.0)
src_mojo.stop_audio()