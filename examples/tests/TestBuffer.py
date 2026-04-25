from mmmaudio import *
src_mojo = MMMAudio(128, graph_name="TestBuffer", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_float("which", 0.0) # no interpolation
src_mojo.send_float("which", 1.0) # linear interpolation
src_mojo.send_float("which", 2.0) # quadratic interpolation
src_mojo.send_float("which", 3.0) # cubic interpolation
src_mojo.send_float("which", 4.0) # lagrange interpolation
src_mojo.send_float("which", 5.0) # sinc interpolation (does not work)

src_mojo.stop_audio()