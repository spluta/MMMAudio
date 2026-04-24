
"""
A simple default graph example that can be used as a starting point for creating your own graphs.
"""

from srcpy import *

# instantiate and load the graph
src_mojo = MMMAudio(128, graph_name="DefaultGraph", package_name="examples")
src_mojo.start_audio() 

src_mojo.send_float("pan", 0)

# set the frequency to a random value
from random import random
src_mojo.send_float("freq", random() * 500 + 100) # set the frequency to a random value

src_mojo.stop_audio()

src_mojo.stop_process()

exit()