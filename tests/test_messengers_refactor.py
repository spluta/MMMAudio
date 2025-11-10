from mmm_src.MMMAudio import MMMAudio
from mmm_utils.functions import midicps

a = MMMAudio(128, graph_name="TestMessengersRefactor", package_name="tests")

a.start_audio()

a.send_bool("bool",True)
a.send_bool("bool",False)

a.send_bools("bools", [True, False, False, True])
a.send_bools("bools", [False, True, True, False])

a.send_float("float", 440.0)
a.send_float("float", 880.0)

a.send_floats("floats", [440.0, 550.0, 660.0])
a.send_floats("floats", [880.0, 990.0, 1100.0])

a.send_int("int", 42)
a.send_int("int", 84)

a.send_ints("ints", [1, 22, 3, 4, 5])
a.send_ints("ints", [5, 4, 3, 2, 1])
a.send_ints("ints", [100,200])

a.send_string("string", "Hello, World!")
a.send_string("string", "Goodbye, World!")

a.send_strings("strings", ["hello", "there", "general", "kenobi"])
a.send_strings("strings", ["goodbye", "there", "general", "grievous"])

a.send_trig("trig")

a.send_trigs("trigs", [True, False, True, True, False])
a.send_trigs("trigs", [False, True, False, False, True])

a.send_bool("tone_0.gate",True)
a.send_bool("tone_1.gate",True)
a.send_float("tone_0.freq",440 * 1.059)
a.send_float("tone_1.freq",midicps(74))
a.send_bool("tone_0.gate",False)
a.send_bool("tone_1.gate",False)

a.stop_audio()