from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestFFTProcess", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_float("onsets_thresh",68)
mmm_audio.send_float("onsets_min_slice_len",3)

mmm_audio.send_int("nscrambles",100)
mmm_audio.send_trig("rescramble")

mmm_audio.send_int("scramble_range",20)

mmm_audio.send_int("lpbin",513)

mmm_audio.stop_audio()

mmm_audio.plot(2048)