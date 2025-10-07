from mmm_src.MMMAudio import MMMAudio
import asyncio
import threading


mmm_audio = MMMAudio(128, graph_name="PlayBufExample", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

# this example uses open sound control to control PlayBuf's playback speed and VAMoogFilter's cutoff frequency
# there is a simple touchosc patch provided for control
# it is looking for /fader1 and /fader2 on port 5005; these can be adjusted
# Start the OSC server on its own thread
# this is a bug, but this thread has to start after audio or audio won't start
from mmm_utils.osc_server import OSCServer
from mmm_utils.functions import *

# Usage:
def osc_msg_handler(key, *args):
    print(f"Received OSC message: {key} with arguments: {args}")
    if key == "/fader1":
        val = lincurve(args[0], 0.0, 1.0, -4.0, 4.0, -1.0)
        print(f"Setting play_rate to {val}")
        mmm_audio.send_msg("play_rate", val)
    elif key == "/fader2":
        val = linexp(args[0], 0.0, 1.0, 100.0, 20000.0)
        print(f"Setting lpf_freq to {val}")

        mmm_audio.send_msg("lpf_freq", val)

# Start server
osc_server = OSCServer("0.0.0.0", 5005, osc_msg_handler)
osc_server.start()

# if you need to adjust and reset the handler function:
osc_server.set_osc_msg_handler(osc_msg_handler)

# Stop server when needed
osc_server.stop()