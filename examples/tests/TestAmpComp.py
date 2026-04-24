from srcpy import *
src_mojo = MMMAudio(128, num_output_channels = 4, graph_name="TestAmpComp", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_float("thresh", -17.0)
src_mojo.send_float("ratio", 4.0)
src_mojo.send_float("attack", 0.01)
src_mojo.send_float("release", 0.5)
src_mojo.send_float("knee_width", 4.0)

src_mojo.stop_audio()
src_mojo.plot(48000*2)