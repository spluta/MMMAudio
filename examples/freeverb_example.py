from mmm_src.MMMAudio import MMMAudio
from mmm_utils.functions import *


mmm_audio = MMMAudio(128, graph_name="FreeverbExample", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

# this example uses open sound control to control Freeverb's parameters
# there is a simple touchosc patch provided for control


from mmm_utils.osc_server import OSCServer

# Usage:
def osc_msg_handler(key, *args):
    if key == "/fader1":
        mmm_audio.send_msg("room_size", args[0])
    elif key == "/fader2":
        val = linexp(args[0], 0.0, 1.0, 100.0, 20000.0)
        mmm_audio.send_msg("lpf_comb", val)
    elif key == "/fader3":
        mmm_audio.send_msg("added_space", args[0])
    elif key == "/fader4":
        mmm_audio.send_msg("mix", args[0])
    else:
        print(f"Unhandled OSC address: {key}")

# Start server
osc_server = OSCServer("0.0.0.0", 5005, osc_msg_handler)
osc_server.start()

# if you need to adjust and reset the handler function:
osc_server.set_osc_msg_handler(osc_msg_handler)

# Stop server when needed
osc_server.stop()