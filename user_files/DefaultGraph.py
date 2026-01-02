


from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="DefaultGraph", package_name="examples")
mmm_audio.start_audio() 



# set the frequency to a random value
from random import random
mmm_audio.send_float("freq", random() * 500 + 100) # set the frequency to a random value