"""use this as a template for your own graphs"""


from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="DefaultGraph", package_name="examples")
mmm_audio.start_audio() 

# set the frequency to a random value
from random import random
mmm_audio.send_msg("freq", random() * 500 + 100, random() * 500 + 100, random() * 500 + 100) # set the frequency to a random value    

import mido
import time
import threading
from mmm_utils.functions import midicps

# find your midi devices
mido.get_input_names()

# open your midi device - you may need to change the device name
in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

def start_midi():
    while True:
        for msg in in_port.iter_pending():
            if msg.type == "note_on":
                mmm_audio.send_msg("freq", midicps(msg.note))  # send the midi message to mmm
        time.sleep(0.01) # Small delay to prevent busy-waiting

midi_thread = threading.Thread(target=start_midi, daemon=True)
# once you start the midi_thread, it should register note_on, note_off, cc, etc from your device and send them to mmm
midi_thread.start()
midi_thread.stop()

mmm_audio.stop_audio()