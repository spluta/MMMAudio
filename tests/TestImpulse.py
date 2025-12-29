from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestImpulse", package_name="tests")
mmm_audio.send_ints("trig", [1, 1])
mmm_audio.send_floats("phase_offsets", [0.3,0.5])
mmm_audio.start_audio() 

mmm_audio.send_ints("trig", [1, 0])
mmm_audio.send_ints("trig", [1, 1])
mmm_audio.send_ints("trig", [0, 1])

mmm_audio.stop_audio()

mmm_audio.send_floats("freqs", [24000.0, 3000])
mmm_audio.send_ints("trig", [1, 1])

mmm_audio.plot(48000)
