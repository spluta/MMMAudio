from mmm_src.MMMAudio import MMMAudio
import asyncio
import threading


mmm_audio = MMMAudio(128, graph_name="FreeverbExample", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

# this example uses open sound control to control Freeverb's parameters
# there is a simple touchosc patch provided for control
thread = threading.Thread(target=asyncio.run, args=(mmm_audio.start_osc_server("0.0.0.0", 5005),), daemon=True)
thread.start()

mmm_audio.stop_audio() # stop/pause the audio thread