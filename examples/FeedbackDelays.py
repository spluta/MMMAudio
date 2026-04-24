"""A simple but awesome sounding feedback delay effect using the FB_Delay UGen."""

from srcpy import *

src_mojo = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")

src_mojo.start_audio() # start the audio thread - or restart it where it left off
src_mojo.stop_audio() # stop/pause the audio thread                

