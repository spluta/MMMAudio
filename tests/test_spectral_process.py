from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestSpectralProcess", package_name="tests")
mmm_audio.start_audio()

mmm_audio.send_int("nscrambles",200)
mmm_audio.send_trig("rescramble")
mmm_audio.send_int("scramble_range",20)

mmm_audio.send_int("lpbin",100)

mmm_audio.stop_audio()