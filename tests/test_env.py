from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestEnv", package_name="tests")
# mmm_audio.start_audio() 

mmm_audio.plot(256)

mmm_audio.send_msg("curve", 16)

mmm_audio.start_audio()

mmm_audio.stop_audio()