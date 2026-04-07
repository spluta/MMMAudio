"""An example showing how to record audio input from a microphone to a buffer and play it back using MIDI note messages."""
import sys
from pathlib import Path

# This example is able to run by pressing the "play" button in VSCode
# that executes the whole file.
# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *


def main():
    # set your audio input and output devices here:
    in_device = "Fireface UCX II (24219339)"
    out_device = "Fireface UCX II (24219339)"

    # in_device = "MacBook Pro Microphone"
    # out_device = "External Headphones"

    # instantiate and load the graph
    mmm_audio = MMMAudio(128, num_input_channels=18, num_output_channels=2, in_device=in_device, out_device=out_device, graph_name="Record", package_name="examples")

    # the default input channel (in the Record_Synth) is 0, but you can change it
    mmm_audio.send_int("set_input_chan", 16) 
    mmm_audio.start_audio() 

    import mido
    import time
    import threading

    # find your midi devices
    mido.get_input_names()

    # open your midi device - you may need to change the device name
    in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

    # Create stop event
    stop_event = threading.Event()
    def start_midi():
        while not stop_event.is_set():
            for msg in in_port.iter_pending():
                if stop_event.is_set():  # Check if we should stop
                    return
                print("Received MIDI message:", end=" ")
                print(msg)

                if msg.type == "note_on" and msg.note == 48:
                    mmm_audio.send_bool("is_recording", True)
                elif msg.type == "note_off" and msg.note == 48:
                    mmm_audio.send_bool("is_recording", False)
            time.sleep(0.01)

    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=False)
    midi_thread.start()

if __name__ == "__main__":
    main()