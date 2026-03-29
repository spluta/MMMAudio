from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestFFTProcessLP", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_int("lpbin",513)

mmm_audio.stop_audio()