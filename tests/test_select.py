from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestSelect", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_msg("which", 1.5)
mmm_audio.send_msg("v0", 99.0)
mmm_audio.send_msg("which", 7.5)

mmm_audio.stop_audio()