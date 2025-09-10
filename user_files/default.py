from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="Default_Graph", package_name="user_files")
mmm_audio.start_audio() 

from random import random
mmm_audio.send_msg("osc_freq", random() * 500 + 100 ) # set the frequency to a random value