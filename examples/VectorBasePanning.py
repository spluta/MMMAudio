"""
An example of Vector Base Amplitude Panning. Inclues a 4 channel speaker array example where speakers are placed at azimuths of -55, 55, -110, and 110 degrees. Also includes a 7-channel surround sound example.

The position of the audio source is controlled by the mouse. The corners of the screen are positioned directly on top of the speakers.
"""

from mmm_python import *
from math import pi

# instantiate and load the graph, change num_output_channels to 7 and uncomment the 7-channel code in the mojo file for a 7-channel surround sound example.
mmm_audio = MMMAudio(128, num_output_channels=4, graph_name="VectorBasePanning", package_name="examples")

mmm_audio.start_audio()

mmm_audio.send_float("az", 0.0 * 2 * pi)
mmm_audio.send_float("az", 0.125 * 2 * pi)
mmm_audio.send_float("az", 0.25 * 2 * pi)
mmm_audio.send_float("az", 0.375 * 2 * pi)
mmm_audio.send_float("az", 0.5 * 2 * pi)
mmm_audio.send_float("az", 0.625 * 2 * pi)
mmm_audio.send_float("az", 0.75 * 2 * pi)
mmm_audio.send_float("az", 0.875 * 2 * pi)


#Enable/disable mouse
mmm_audio.send_bool("mouse", True)
mmm_audio.send_bool("mouse", False)

# for Wayland use the fake mouse
MMMAudio.fake_mouse()

mmm_audio.stop_audio()

mmm_audio.plot(48000)