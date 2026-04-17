
from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestTopNFreqs", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_floats("freqs", [200.0, 600.0, 800.0])

mmm_audio.send_floats("freqs", mprint([exprand(200.0, 500.0), exprand(600.0, 800.0), exprand(800.0, 1200.0)]))
