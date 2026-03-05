from mmm_python import *

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestUpsample", package_name="examples.tests")
mmm_audio.start_audio() 



mmm_audio.stop_audio()  

mmm_audio.plot(1000)