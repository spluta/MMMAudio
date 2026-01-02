"""use the mouse to control an overdriven feedback delay"""

from mmm_python.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off
mmm_audio.stop_audio() # stop/pause the audio thread                

