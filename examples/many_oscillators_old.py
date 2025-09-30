"""Example showing how to use ManyOscillators.mojo with MMMAudio.

You can change the number of oscillators dynamically by sending a 'set_num_pairs' message.
"""

from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.send_msg("set_num_pairs", 2)  # set to 2 pairs of oscillators

mmm_audio.send_msg("set_num_pairs", 14)  # change to 14 pairs of oscillators

mmm_audio.send_msg("set_num_pairs", 300)  # change to 300 pairs of oscillators

mmm_audio.stop_audio() # stop/pause the audio thread


# ----------- running python in full priority mode -------------
# if you are expericencing audio dropouts, these can be avoided by giving python the highest "nice" priority
# unfortunately this can't be done from the terminal that vscode automatically launches
# it can only be done from a user made terminal
# from a new terminal window and from the MMMAudio directory run "sudo nice -n -20 venv/bin/python" to run python in sudo mode with highest priority
# then copy and paste your code, like the example below, into the terminal repl to run it

from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off