from mmm_src.MMMAudio import MMMAudio

# [ ] safety checks on fft sizes
# [ ] test with units
# [ ] test power mags
# [ ] test against librosa
# [ ] make sure documentation is in order
# [ ] explain static methods
# [ ] make the example more comprehensive

mmm_audio = MMMAudio(128, graph_name="AnalysisExample", package_name="examples")
mmm_audio.start_audio()

mmm_audio.send_float("freq", 210.5)
mmm_audio.send_float("which", 2.0)

mmm_audio.stop_audio()