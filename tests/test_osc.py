from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestOsc", package_name="tests")
mmm_audio.start_audio() 


mmm_audio.stop_audio()  