from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestDelay", package_name="examples.tests")
mmm_audio.start_audio() 
mmm_audio.stop_audio()
mmm_audio.send_float("del_time", 2.0/mmm_audio.sample_rate)

mmm_audio.send_trig("trig")
mmm_audio.send_trig("trig")
mmm_audio.send_trig("trig")

mmm_audio.stop_audio()

mmm_audio.send_float("freq", 5)
mmm_audio.send_trig("trig")

mmm_audio.plot(2048)