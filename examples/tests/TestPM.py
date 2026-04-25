from mmmaudio import *


# instantiate and load the graph
src_mojo = MMMAudio(128, num_output_channels=2, graph_name="TestPM", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.stop_audio()

src_mojo.plot(256)