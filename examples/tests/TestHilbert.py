from cmath import pi

from mmmaudio import *

src_mojo = MMMAudio(128, graph_name="TestHilbert", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_float("freq", 150)
src_mojo.send_float("radians", 0.0)
src_mojo.send_float("radians", pi/2.0)
src_mojo.send_float("radians", pi)
src_mojo.send_float("radians", 3*pi/2.0)

src_mojo.stop_audio()
src_mojo.plot(2048)
