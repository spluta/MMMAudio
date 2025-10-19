from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestSVF", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_msg("freq", 340.0)
mmm_audio.send_msg("cutoff", 400.0)
mmm_audio.send_msg("res", 6.0)

mmm_audio.stop_audio()