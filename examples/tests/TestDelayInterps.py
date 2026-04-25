from mmmaudio import *

src_mojo = MMMAudio(128, graph_name="TestDelayInterps", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_float("max_delay_time", 0.00827349827)
src_mojo.send_float("max_delay_time", 0.99238497837)
src_mojo.send_float("max_delay_time", 0.2)
src_mojo.send_float("lfo_freq",1.03)
src_mojo.send_float("mix", 0.5 )

# listen to the differences
src_mojo.send_float("which_delay", 0) # none
src_mojo.send_float("which_delay", 1) # linear
src_mojo.send_float("which_delay", 2) # quadratic
src_mojo.send_float("which_delay", 3) # cubic
src_mojo.send_float("which_delay", 4) # lagrange

src_mojo.stop_audio()

src_mojo.plot(256)