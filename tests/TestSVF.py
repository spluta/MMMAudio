from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestSVF", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_float("freq", 840.0)
mmm_audio.send_float("cutoff", 10.0)
mmm_audio.send_float("res", 8.0)

mmm_audio.stop_audio()