from srcpy import *
src_mojo = MMMAudio(128, graph_name="TestWriteBuffer", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.stop_audio()