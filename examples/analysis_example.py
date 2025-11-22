# [x] safety checks on fft sizes
# [x] test with units
# [x] test power mags
# [x] test against librosa
# [ ] make sure documentation is in order
# [ ] explain static methods
# [ ] make the example more comprehensive


from mmm_src.MMMAudio import MMMAudio

ma = MMMAudio(128, graph_name="AnalysisExample", package_name="examples")
ma.start_audio()

ma.send_float("freq", 210.5)
ma.send_float("which", 2.0)
ma.stop_audio()