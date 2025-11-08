from mmm_src.MMMAudio import MMMAudio
mmm_audio = MMMAudio(128, graph_name="TestMessengersRefactor", package_name="tests")
mmm_audio.start_audio()

# mmm_audio.send_float("float_test", 1.4)

# mmm_audio.send_float("should_warn_re_float", 2.5)

# mmm_audio.send_gate("gate_test", True)
# mmm_audio.send_gate("gate_test", False)

# mmm_audio.send_gate("should_warn_re_gate", True)

# mmm_audio.send_trig("trig_test")

# mmm_audio.send_trig("should_warn_re_trig")

mmm_audio.send_list("tone_0.test_list", [9.9,11.12,13.13,14.14])
mmm_audio.send_trig("trig_test")

# mmm_audio.send_float("vol", -100.0)
mmm_audio.send_float("vol", -100.0)

mmm_audio.send_float("tone_0.freq", 500)
mmm_audio.send_float("tone_1.freq", 700)

mmm_audio.send_int("test_int", -1)

mmm_audio.send_trig("tone_0.test_bool")
mmm_audio.stop_audio()

# mmm_audio.send_int("should_warn_re_int", 7)

mmm_audio.send_text("tone_0.file_name", ["wavy.wav", "gravy.wav"])
mmm_audio.send_text("tone_0.file_name", "wavy.wav", "gravy.wav")
mmm_audio.stop_audio()

mmm_audio.send_text("text_test", *["Line 1", "Line 2"])

mmm_audio.stop_audio()
