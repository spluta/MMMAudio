from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(2048, graph_name="PaulStretch", package_name="examples")
mmm_audio.start_audio()

mmm_audio.send_float("dur_mult", 20.0)
mmm_audio.send_float("dur_mult", 40.0)

mmm_audio.stop_audio()