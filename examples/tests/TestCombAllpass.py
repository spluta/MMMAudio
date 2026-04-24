from srcpy import *
src_mojo = MMMAudio(128, graph_name="TestCombAllpass", package_name="examples.tests")
src_mojo.start_audio() 

src_mojo.send_float("which_fx", 0.0) # comb filter with feedback set to 0.9
src_mojo.send_float("which_fx", 1.0) # allpass filter with feedback set to 0.9
src_mojo.send_float("which_fx", 2.0) # comb filter with decay_time set to 1 second
src_mojo.send_float("which_fx", 3.0) # allpass filter with delay_time set to 1 second
src_mojo.send_float("which_fx", 4.0) # low pass comb filter with feedback set to 0.9 and cutoff set to 10000 Hz

src_mojo.send_float("delay_time", 0.005)

src_mojo.stop_audio()
src_mojo.plot(48000)