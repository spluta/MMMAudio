from srcpy import *

# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestOnePole", package_name="examples.tests")
src_mojo.start_audio() 


src_mojo.stop_audio()