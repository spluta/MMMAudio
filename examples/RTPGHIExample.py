from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="RTPGHIExample", package_name="examples")
mmm_audio.start_audio()

mmm_audio.send_int("which",0) # original phases (default)
mmm_audio.send_int("which",1) # random phases
mmm_audio.send_int("which",2) # RTPGHI phases

mmm_audio.stop_audio()
