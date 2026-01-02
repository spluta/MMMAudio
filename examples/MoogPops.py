from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="MoogPops", package_name="examples")
mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.stop_audio() # stop the audio thread
mmm_audio.plot(10000)