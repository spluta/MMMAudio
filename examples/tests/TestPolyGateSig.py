from mmmaudio import *
src_mojo = MMMAudio(128, graph_name="TestPolyGateSig", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_floats("dust_vals", [1.0, 6.0])

src_mojo.stop_audio()