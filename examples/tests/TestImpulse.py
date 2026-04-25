from mmmaudio import *


# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="TestImpulse", package_name="examples.tests")
src_mojo.send_ints("trig", [1, 1])
src_mojo.send_floats("phase_offsets", [0.3,0.5])
src_mojo.start_audio() 

src_mojo.send_ints("trig", [1, 0])
src_mojo.send_ints("trig", [1, 1])
src_mojo.send_ints("trig", [0, 1])

src_mojo.send_floats("phase_offsets", [0.0,0.0])

src_mojo.stop_audio()

src_mojo.send_floats("freqs", [24000.0, 3000])
src_mojo.send_ints("trig", [1, 1])

src_mojo.send_floats("freqs", [100, 300])

src_mojo.plot(500)
