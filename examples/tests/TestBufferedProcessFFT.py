from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestBufferedProcessFFT", package_name="examples.tests")
mmm_audio.start_audio()

# set the cutoff bin. all bins above this will be zeroed out
mmm_audio.send_int("bin",30)
mmm_audio.send_int("bin",50)

mmm_audio.stop_audio()