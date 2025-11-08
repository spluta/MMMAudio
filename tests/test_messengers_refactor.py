from mmm_src.MMMAudio import MMMAudio
import random
mmm_audio = MMMAudio(128, graph_name="TestMessengersRefactor", package_name="tests")
mmm_audio.start_audio()

mmm_audio.send_float("tone_0.freq", 500)
mmm_audio.send_float("tone_1.freq", 700)

mmm_audio.send_floats("test_floats", [random.uniform(200.0, 800.0) for _ in range(2)])

mmm_audio.send_int("test_int", 1)
mmm_audio.send_int("test_int", -1)

mmm_audio.send_ints("tone_0.test_ints", 9,11,13,14)

mmm_audio.send_trig("test_trig") #should make the sines 3hz apart

mmm_audio.send_float("vol", -100.0)

mmm_audio.send_trig("tone_0.test_trig")
mmm_audio.send_gate("tone_0.test_gate", True)
mmm_audio.send_gate("tone_0.test_gate", False)

mmm_audio.send_gates("test_gates", [True, False, False, True])


mmm_audio.send_texts("tone_0.file_name", ["wavy.wav", "gravy.wav"])
mmm_audio.send_texts("tone_0.file_name", "wavy.wav", "gravy.wav")
mmm_audio.send_texts("tone_0.file_name", "wavy.wav")
mmm_audio.send_texts("text_test", ["Line 1", "Line 2"])

mmm_audio.stop_audio()
