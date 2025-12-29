from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestCombAllpass", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_float("which_fx", 0.0)
mmm_audio.send_float("which_fx", 1.0)
mmm_audio.send_float("which_fx", 2.0)
mmm_audio.send_float("which_fx", 3.0)

mmm_audio.send_float("delay_time", 0.005)

mmm_audio.stop_audio()
mmm_audio.plot(11000)

1/0.4*48000