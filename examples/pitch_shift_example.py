"""this uses the mouse to control granular playback of the buffer
left and right moves around in the buffer. up and down controls rate of triggers.
"""

from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, num_input_channels = 12, graph_name="PitchShiftExample", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.send_msg("pitch_shift", 1.10)
mmm_audio.send_msg("grain_size", 0.4)
mmm_audio.send_msg("pitch_dispersion", 0.4)
mmm_audio.send_msg("time_dispersion", 0.5)

mmm_audio.stop_audio()  # stop the audio thread