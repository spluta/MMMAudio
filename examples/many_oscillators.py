"""Example showing how to use ManyOscillators.mojo with MMMAudio.

You can change the number of oscillators dynamically by sending a 'set_num_pairs' message.
"""

from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

mmm_audio.send_msg("set_num_pairs", 2)  # set to 2 pairs of oscillators

mmm_audio.send_msg("set_num_pairs", 14)  # change to 4 pairs of oscillators

mmm_audio.send_msg("set_num_pairs", 50)  # change to 4 pairs of oscillators

mmm_audio.stop_audio() # stop/pause the audio thread


# ----------- running python in full priority mode -------------
# if you are expericencing audio dropouts, these can be avoided by giving python the highest "nice" priority
# unfortunately this can't be done from the terminal that vscode automatically launches
# it can only be done from a user made terminal
# from a new terminal window and from the MMMAudio directory run "sudo venv/bin/python" to run python in sudo mode
# then copy and paste your code, like the example below (adjusting the nice value below 0), into the terminal repl to run it

from mmm_src.MMMAudio import MMMAudio

import os
import sys
import psutil

# Get the current process ID
process = psutil.Process(os.getpid())
process.nice()

# Set a custom nice value.
# The range is -20 (high priority) to 19 (low priority) on Linux/macOS.
# Values depend on the OS for Windows.
try:
    process.nice(-20) # Set to a higher priority
    print(f"Set process priority to: {process.nice()}")
except (psutil.AccessDenied, psutil.NoSuchProcess):
    print("Could not change process priority.")

mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off