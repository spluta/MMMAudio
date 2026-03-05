from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestDelayInterps", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_float("max_delay_time", 0.00827349827)
mmm_audio.send_float("max_delay_time", 0.99238497837)
mmm_audio.send_float("max_delay_time", 0.2)
mmm_audio.send_float("lfo_freq",1.03)
mmm_audio.send_float("mix", 0.5 )

# listen to the differences
mmm_audio.send_float("which_delay", 0) # none
mmm_audio.send_float("which_delay", 1) # linear
mmm_audio.send_float("which_delay", 2) # quadratic
mmm_audio.send_float("which_delay", 3) # cubic
mmm_audio.send_float("which_delay", 4) # lagrange

mmm_audio.stop_audio()

mmm_audio.plot(256)