from srcpy import *

src_mojo = MMMAudio(128, graph_name="TestFFTProcess", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_float("onsets_thresh",68)
src_mojo.send_float("onsets_min_slice_len",3)

src_mojo.send_int("nscrambles",100)
src_mojo.send_trig("rescramble")

src_mojo.send_int("scramble_range",20)

src_mojo.send_int("lpbin",513)

src_mojo.stop_audio()

src_mojo.plot(2048)