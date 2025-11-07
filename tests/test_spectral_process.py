from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestSpectralProcess", package_name="tests")
mmm_audio.start_audio()

mmm_audio.send_int("bin",11)

mmm_audio.stop_audio()