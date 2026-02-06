from mmm_python.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestFFTProcess", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_int("nscrambles",300)
mmm_audio.send_trig("rescramble")
mmm_audio.send_int("scramble_range",10)

mmm_audio.send_int("lpbin",60)

mmm_audio.stop_audio()

mmm_audio.plot(2048)