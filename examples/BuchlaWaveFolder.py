"""Buchla Wavefolder example."""

from mmm_python.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="BuchlaWaveFolder_AD", package_name="examples")

# to hear the version without Anti-Aliasing, use:
# mmm_audio = MMMAudio(128, graph_name="BuchlaWaveFolder", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.stop_audio()
mmm_audio.plot(4000)

# plot the spectrum of the the plotted output
from numpy import fft
from matplotlib import pyplot as plt
spectrum = fft.rfft(mmm_audio.returned_samples[:, 0])
plt.plot(spectrum)
plt.show()