"""this uses the mouse to control granular playback of the buffer
left and right moves around in the buffer. up and down controls rate of triggers.
"""

from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="Grains", package_name="examples")
mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.stop_audio() # stop/pause the audio thread