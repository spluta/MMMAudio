"""Example showing how to use ManyOscillators.mojo with MMMAudio.

You can change the number of oscillators dynamically by sending a 'set_num_pairs' message.
"""

from mmm_src.MMMAudio import MMMAudio

# MMMAudio is the main class for handling audio input and output, # so it needs to be created and told what 'graph' to use.
# A 'graph' is a collection of audio processing modules 
# connected together by the user into a signal chain to create the 
# desired DSP. In this example, the user has created a
# graph called "ManyOscillators" in the .mojo file called  
# "ManyOscillators.mojo". (Currently the file and graph need to 
# share the same name. This will likely change.) 
# That file is in the "examples" directory.
# It is called a "package" because Mojo can consider a directory 
# as a package if it contains a __init__.mojo file (just like 
# Python can if it contains a __init__.py file).
mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.send_int("set_num_pairs", 2)  # set to 2 pairs of oscillators

mmm_audio.send_int("set_num_pairs", 14)  # change to 14 pairs of oscillators

mmm_audio.send_int("set_num_pairs", 300)  # change to 300 pairs of oscillators

mmm_audio.stop_audio() # stop/pause the audio thread
