
from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestTopNFreqs", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_floats("freqs", [430.3572274538059, 697.4350697130784, 957.7907358252581])

mmm_audio.send_floats("freqs", [475.4213563956452, 725.4641549887164, 1169.7061377666523])

mmm_audio.send_floats("freqs", mprint([exprand(200.0, 500.0), exprand(600.0, 800.0), exprand(800.0, 1200.0)]))

mmm_audio.stop_audio()
