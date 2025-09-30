from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestImpulse", package_name="tests")
mmm_audio.send_msg("trig", 1, 1)
mmm_audio.start_audio() 

mmm_audio.send_msg("trig", 1, 0)
mmm_audio.send_msg("trig", 1, 1)
mmm_audio.send_msg("trig", 0, 1)

mmm_audio.stop_audio()

mmm_audio.send_msg("freq", 200.0)
mmm_audio.send_msg("trig", 1, 1)

mmm_audio.plot(1024)
