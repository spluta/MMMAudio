from srcpy import *

src_mojo = MMMAudio(128, graph_name="TestFFTProcessLP", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_int("lpbin",513)

src_mojo.stop_audio()