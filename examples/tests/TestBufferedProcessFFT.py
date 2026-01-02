from mmm_python.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestBufferedProcessFFT", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_int("bin",30)
mmm_audio.send_int("bin",50)

mmm_audio.stop_audio()