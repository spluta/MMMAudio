from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestCombAllpass", package_name="examples.tests")
mmm_audio.start_audio() 

mmm_audio.send_float("which_fx", 0.0) # comb filter with feedback set to 0.9
mmm_audio.send_float("which_fx", 1.0) # allpass filter with feedback set to 0.9
mmm_audio.send_float("which_fx", 2.0) # comb filter with decay_time set to 1 second
mmm_audio.send_float("which_fx", 3.0) # allpass filter with delay_time set to 1 second
mmm_audio.send_float("which_fx", 4.0) # low pass comb filter with feedback set to 0.9 and cutoff set to 10000 Hz

mmm_audio.send_float("delay_time", 0.005)

mmm_audio.stop_audio()
mmm_audio.plot(48000)

1/0.4*48000