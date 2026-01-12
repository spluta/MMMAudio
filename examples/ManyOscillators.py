"""Example showing how to use ManyOscillators.mojo with MMMAudio.

You can change the number of oscillators dynamically by sending a 'set_num_pairs' message.
"""

from mmm_python.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="ManyOscillators", package_name="examples")
mmm_audio.start_audio()

mmm_audio.send_int("num_pairs", 2)  # set to 2 pairs of oscillators

mmm_audio.send_int("num_pairs", 14)  # change to 14 pairs of oscillators

mmm_audio.send_int("num_pairs", 300)  # change to 300 pairs of oscillators

mmm_audio.stop_audio() # stop/pause the audio thread
