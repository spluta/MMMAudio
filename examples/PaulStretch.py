# PaulStretch is an FFT – based extreme time, stretching algorithm invented by Paul Nasca in 2006

from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(2048, graph_name="PaulStretch", package_name="examples")
mmm_audio.start_audio()

# change how slow the audio gets stretched
mmm_audio.send_float("dur_mult", 10.0)
mmm_audio.send_float("dur_mult", 100.0)
mmm_audio.send_float("dur_mult", 40.0)
mmm_audio.send_float("dur_mult", 10000.0)

mmm_audio.stop_audio()