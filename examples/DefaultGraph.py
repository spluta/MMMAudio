
"""
A simple default graph example that can be used as a starting point for creating your own graphs.
"""

from mmm_python import *

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="DefaultGraph", package_name="examples")
mmm_audio.start_process()
mmm_audio.start_audio() 

mmm_audio.send_float("pan", 0)

# set the frequency to a random value
from random import random
mmm_audio.send_float("freq", random() * 500 + 100) # set the frequency to a random value