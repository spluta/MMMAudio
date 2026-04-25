from mmmaudio import *

# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestHardClipADAA", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.stop_audio()

src_mojo.plot(48000//8)