from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph

# PanAz is not quite right as of yet
mmm_audio = MMMAudio(128, graph_name="PanAzExample", package_name="examples", num_output_channels=8)
mmm_audio.start_audio() 

mmm_audio.send_msg("set_num_speakers", 8 ) # set the number of speakers to between 2 and 8

mmm_audio.stop_audio()

from random import random
mmm_audio.send_msg("osc_freq", random() * 500 + 100 ) # set the frequency to a random value