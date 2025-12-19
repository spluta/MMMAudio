from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="TestBuffer", package_name="tests")
mmm_audio.start_audio()

mmm_audio.send_float("which", 0.0)
mmm_audio.send_float("which", 1.0)
mmm_audio.send_float("which", 2.0)
mmm_audio.send_float("which", 3.0)
mmm_audio.send_float("which", 4.0)
mmm_audio.send_float("which", 5.0)

mmm_audio.stop_audio()