
from mmmaudio import *
src_mojo = MMMAudio(128, graph_name="TestTopNFreqs", package_name="examples.tests")
src_mojo.start_audio()

src_mojo.send_floats("freqs", [430.3572274538059, 697.4350697130784, 957.7907358252581])

src_mojo.send_floats("freqs", [475.4213563956452, 725.4641549887164, 1169.7061377666523])

src_mojo.send_floats("freqs", mprint([exprand(200.0, 500.0), exprand(600.0, 800.0), exprand(800.0, 1200.0)]))

src_mojo.stop_audio()
