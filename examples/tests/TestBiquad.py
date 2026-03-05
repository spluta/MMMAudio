from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestBiquad", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_float("cutoff", 500.0)
mmm_audio.send_float("q", 8.0)

mmm_audio.stop_audio()