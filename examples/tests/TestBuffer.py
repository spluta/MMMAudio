from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestBuffer", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_float("which", 0.0) # no interpolation
mmm_audio.send_float("which", 1.0) # linear interpolation
mmm_audio.send_float("which", 2.0) # quadratic interpolation
mmm_audio.send_float("which", 3.0) # cubic interpolation
mmm_audio.send_float("which", 4.0) # lagrange interpolation
mmm_audio.send_float("which", 5.0) # sinc interpolation (does not work)

mmm_audio.stop_audio()