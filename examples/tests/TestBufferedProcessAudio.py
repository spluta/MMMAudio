from srcpy import *

src_mojo = MMMAudio(128, graph_name="TestBufferedProcessAudio", package_name="examples.tests")
src_mojo.start_audio() 

# listen to only the processed audio
src_mojo.send_float("which",1.0)

# volume should go down
src_mojo.send_float("vol",-12.0)

# unprocessed audio still at full volume
src_mojo.send_float("which",0.0)

# bring volume back up
src_mojo.send_float("vol",0.0)

# should hear a tiny delay fx when mixed?
src_mojo.send_float("which",0.5)

src_mojo.stop_audio()

src_mojo.plot(44100)