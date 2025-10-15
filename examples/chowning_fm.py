"""
These examples are adapted from Chowning's original paper on FM synthesis: https://web.eecs.umich.edu/~fessler/course/100/misc/chowning-73-tso.pdf and can also be found in "Computer Music" by Dodge and Jerse. pg. 123-127.
"""

from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="ChowningFM", package_name="examples")
mmm_audio.start_audio()

# bell
mmm_audio.send_msg("m_freq", 280.0)
mmm_audio.send_msg("c_freq", 200.0)
mmm_audio.send_msg("amp_vals",0.0,1.0,0.2,0.0)
mmm_audio.send_msg("amp_times",0.001,1.8,1.7)
mmm_audio.send_msg("amp_curves", 1,1,1)
mmm_audio.send_msg("index_vals", 10.0,2.0,0.0)
mmm_audio.send_msg("index_times", 1.8,1.7)
mmm_audio.send_msg("index_curves", 1,1)
mmm_audio.send_msg("trigger", 1.0)

# woodblock
mmm_audio.send_msg("m_freq", 55.0)
mmm_audio.send_msg("c_freq", 80.0)
mmm_audio.send_msg("amp_vals", 0.75, 1.0,  0.6,  0.2, 0.0)
mmm_audio.send_msg("amp_times",  0.02, 0.02, 0.06, 0.1)
mmm_audio.send_msg("amp_curves", 1,    1,    1,    1)
mmm_audio.send_msg("index_vals", 25.0, 0.0)
mmm_audio.send_msg("index_times",  0.012)
mmm_audio.send_msg("index_curves", 1)
mmm_audio.send_msg("trigger", 1.0)

# brass
mmm_audio.send_msg("m_freq", 440.0)
mmm_audio.send_msg("c_freq", 440.0)
mmm_audio.send_msg("amp_vals", 0, 1, 0.7, 0.7, 0)
mmm_audio.send_msg("amp_times",  0.075, 0.050, 0.4, 0.06)
mmm_audio.send_msg("amp_curves", 1,    1,    1,    1)
mmm_audio.send_msg("index_vals", 0, 5, 3.5, 3.5, 0)
mmm_audio.send_msg("index_times",  0.075, 0.050, 0.4, 0.06)
mmm_audio.send_msg("index_curves", 1,1,1,1)
mmm_audio.send_msg("trigger", 1.0)

# brass (less bright)
mmm_audio.send_msg("m_freq", 440.0)
mmm_audio.send_msg("c_freq", 440.0)
mmm_audio.send_msg("amp_vals", 0, 1, 0.7, 0.7, 0)
mmm_audio.send_msg("amp_times",  0.075, 0.050, 0.4, 0.06)
mmm_audio.send_msg("amp_curves", 1,    1,    1,    1)
mmm_audio.send_msg("index_vals", 0, 3, 2.1, 2.1, 0)
mmm_audio.send_msg("index_times",  0.075, 0.050, 0.4, 0.06)
mmm_audio.send_msg("index_curves", 1,1,1,1)
mmm_audio.send_msg("trigger", 1.0)

# clarinet
mmm_audio.send_msg("m_freq", 600.0)
mmm_audio.send_msg("c_freq", 900.0)
mmm_audio.send_msg("amp_vals", 0, 1, 1, 0)
mmm_audio.send_msg("amp_times",  0.087, 0.4, 0.087)
mmm_audio.send_msg("amp_curves", 1, 1, 1)
mmm_audio.send_msg("index_vals", 4, 2)
mmm_audio.send_msg("index_times",  0.073)
mmm_audio.send_msg("index_curves", 1)
mmm_audio.send_msg("trigger", 1.0)

# stop audio
mmm_audio.stop_audio()
