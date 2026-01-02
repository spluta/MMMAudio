from mmm_python.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestSplay", package_name="examples.tests")
mmm_audio.start_audio() 


mmm_audio.stop_audio()  

