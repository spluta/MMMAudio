from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestPatterns", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_int("which", 0)
mmm_audio.send_int("which", 1)
mmm_audio.send_int("which", 2)

