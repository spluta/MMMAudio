from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestBufferedProcess", package_name="examples.tests")
mmm_audio.start_audio() 

mmm_audio.send_float("factor",2478.0)
mmm_audio.stop_audio()