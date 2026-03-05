from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestRMS", package_name="examples.tests")
mmm_audio.start_audio() 
mmm_audio.send_float("vol",-12.0)
mmm_audio.send_float("vol",0.0)
mmm_audio.stop_audio()