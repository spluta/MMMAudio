from srcpy import *

src_mojo = MMMAudio(128, graph_name="TestDelay", package_name="examples.tests")
src_mojo.start_audio() 
src_mojo.stop_audio()
src_mojo.send_float("del_time", 2.0/src_mojo.sample_rate)

src_mojo.send_trig("trig")
src_mojo.send_trig("trig")
src_mojo.send_trig("trig")

src_mojo.stop_audio()

src_mojo.send_float("freq", 5)
src_mojo.send_trig("trig")

src_mojo.plot(2048)