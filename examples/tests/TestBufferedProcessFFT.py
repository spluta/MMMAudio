from srcpy import *

src_mojo = MMMAudio(128, graph_name="TestBufferedProcessFFT", package_name="examples.tests")
src_mojo.start_audio()

# set the cutoff bin. all bins above this will be zeroed out
src_mojo.send_int("bin",30)
src_mojo.send_int("bin",50)

src_mojo.stop_audio()