from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, num_input_channels = 12, graph_name="PitchShiftExample", package_name="examples")
mmm_audio.send_int("in_chan", 0) # set input channel to your input source
mmm_audio.start_audio() # start the audio thread - or restart it where it left off


mmm_audio.send_float("which_input", 0)
mmm_audio.send_float("pitch_shift", 0.5)
mmm_audio.send_float("grain_size", 0.4)

mmm_audio.send_float("pitch_dispersion", 0.4)

mmm_audio.send_float("time_dispersion", 0.5)

mmm_audio.send_float("pitch_dispersion", 0.0)
mmm_audio.send_float("time_dispersion", 0.0)

mmm_audio.start_audio()
mmm_audio.stop_audio()  # stop the audio thread

mmm_audio.plot(44000)