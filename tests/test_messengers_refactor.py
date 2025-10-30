from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="TestMessengersRefactor", package_name="tests")
mmm_audio.start_audio() 

mmm_audio.send_float("float_test", 1.4)

mmm_audio.send_float("should_warn_re_float", 2.5)

mmm_audio.send_gate("gate_test", True)
mmm_audio.send_gate("gate_test", False)

mmm_audio.send_float("should_warn_re_gate", True)

mmm_audio.send_trig("trig_test")

mmm_audio.send_trig("should_warn_re_trig")

mmm_audio.send_list("list_test", [])

mmm_audio.send_float("freq", 440.0)

mmm_audio.send_text("text_test", "Hello, Messengers!")

mmm_audio.stop_audio()