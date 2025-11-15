from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestPitchYin", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_float("freq", 110.5)

mmm_audio.stop_audio()