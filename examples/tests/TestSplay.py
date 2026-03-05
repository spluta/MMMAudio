from mmm_python import *

# instantiate and load the graph
mmm_audio = MMMAudio(128, num_output_channels=8, graph_name="TestSplay", package_name="examples.tests")
mmm_audio.start_audio() 


mmm_audio.stop_audio()  

