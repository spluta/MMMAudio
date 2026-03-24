from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestPolyGateSig", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_floats("dust_vals", [1.0, 6.0])

mmm_audio.stop_audio()