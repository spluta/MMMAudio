"""A simple but awesome sounding feedback delay effect using the FB_Delay UGen."""

from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off
mmm_audio.stop_audio() # stop/pause the audio thread                

