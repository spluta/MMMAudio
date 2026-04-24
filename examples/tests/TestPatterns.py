from srcpy import *
src_mojo = MMMAudio(128, graph_name="TestPatterns", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_int("which", 0)
src_mojo.send_int("which", 1)
src_mojo.send_int("which", 2)

