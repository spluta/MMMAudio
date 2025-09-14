from mmm_src.MMMAudio import *
list_audio_devices()

# instantiate and load the graph
mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=12, in_device="Fireface UFX+ (24059506)", out_device="Fireface UFX+ (24059506)", graph_name="Record", package_name="examples")
mmm_audio.start_audio() 

mmm_audio.send_msg("print_inputs")

# mmm_audio.send_msg("start_recording")

import mido
import time
import threading

# find your midi devices
mido.get_input_names()

# open your midi device - you may need to change the device name
in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

def start_midi():
    while True:
        for msg in in_port.iter_pending():
            print(msg)
            mmm_audio.send_midi(msg)
        time.sleep(0.01) # Small delay to prevent busy-waiting

midi_thread = threading.Thread(target=start_midi, daemon=True)
# once you start the midi_thread, it should register note_on, note_off, cc, etc from your device and send them to mmm
midi_thread.start()


midi_thread.stop()

mmm_audio.stop_audio()