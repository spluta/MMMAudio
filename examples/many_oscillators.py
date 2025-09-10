from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

# ManyOscillators.mojo is looking for a "set_num_pairs" message that will tell it to change the number of oscillator pairs

mmm_audio.send_msg("set_num_pairs", 2)  # set to 2 pairs of oscillators

mmm_audio.send_msg("set_num_pairs", 14)  # change to 4 pairs of oscillators

mmm_audio.send_msg("set_num_pairs", 50)  # change to 4 pairs of oscillators

mmm_audio.stop_audio() # stop/pause the audio thread