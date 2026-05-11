from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="FFTScramble", package_name="examples")
mmm_audio.start_audio()

mmm_audio.send_trig("scramble")
mmm_audio.send_int("n_scrambles",180) # default is 30
mmm_audio.send_int("scramble_range",30) # default is 10

mmm_audio.stop_audio()