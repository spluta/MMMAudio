from mmm_src.MMMAudio import MMMAudio

ma = MMMAudio(128, graph_name="AnalysisExample", package_name="examples")
ma.start_audio()

ma.send_float("freq", 240.5)
ma.send_float("which", 2.0)
ma.stop_audio()