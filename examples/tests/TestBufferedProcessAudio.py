from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestBufferedProcessAudio", package_name="examples.tests")
mmm_audio.start_audio() 

# listen to only the processed audio
mmm_audio.send_float("which",1.0)

# volume should go down
mmm_audio.send_float("vol",-12.0)

# unprocessed audio still at full volume
mmm_audio.send_float("which",0.0)

# bring volume back up
mmm_audio.send_float("vol",0.0)

# should hear a tiny delay fx when mixed?
mmm_audio.send_float("which",0.5)

mmm_audio.stop_audio()

mmm_audio.plot(44100)