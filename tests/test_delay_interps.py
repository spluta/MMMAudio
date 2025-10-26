from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestDelayInterps", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_msg("max_delay_time", 0.00827349827)
mmm_audio.send_msg("max_delay_time", 0.9238497837)
mmm_audio.send_msg("max_delay_time", 1.0)
mmm_audio.send_msg("lfo_freq",0.1)
mmm_audio.send_msg("mix", 0.99)

mmm_audio.send_msg("mouse_onoff", 0)  # disable mouse control of delay time
mmm_audio.send_msg("mouse_onoff", 1)  # enable mouse control of delay time

# listen to the differences
mmm_audio.send_msg("which_delay", 0) # none
mmm_audio.send_msg("which_delay", 1) # linear
mmm_audio.send_msg("which_delay", 2) # cubic
mmm_audio.send_msg("which_delay", 3) # lagrange

mmm_audio.stop_audio()