from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestVAMoogLadder", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_float("which", 0.0)
mmm_audio.send_float("which", 1.0)
mmm_audio.send_float("which", 2.0)


mmm_audio.stop_audio()