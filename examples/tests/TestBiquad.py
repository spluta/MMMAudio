from mmmaudio import *

src_mojo = MMMAudio(128, graph_name="TestBiquad", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_float("cutoff", 500.0)
src_mojo.send_float("q", 8.0)

src_mojo.stop_audio()