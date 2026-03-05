"""
A polyphonic synthesizer controlled via a MIDI keyboard.

This example demonstrates a couple differnt concepts:
- How to connect to a MIDI keyboard using the mido library
- How to use a MIDI keyboard to send note and control change messages to MMMAudio.
- How to use Pseq from mmm_python.Patterns to cycle through voices for polyphonic note allocation.
- How to create a thread to handle incoming MIDI messages in the background.

This example is able to run by pressing the "play" button in VSCode or compiling and running the whole file on the command line.

This uses the same MidiSequencer.mojo graph as the MidiSequencer example, but instead of using a sequencer to trigger notes, it uses a MIDI keyboard.
"""


import sys
from pathlib import Path

# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *

def main():
    # instantiate and load the graph - notice we are using the MidiSequencer graph here (the same as in the MidiSequencer example)
    mmm_audio = MMMAudio(128, graph_name="MidiSequencer", package_name="examples")
    mmm_audio.start_audio()



    # this next chunk of code is all about using a midi keyboard to control the synth---------------

    import threading
    import mido
    import time
    from mmm_python.python_utils import linexp, linlin, midicps, cpsmidi
    from mmm_python.Patterns import Pseq, Pxrand

    # find your midi devices
    mido.get_input_names()

    # open your midi device - you may need to change the device name
    in_port = mido.open_input('Oxygen Pro Mini USB MIDI')


    voice_seq = Pseq(list(range(8)))

    # Create stop event
    global stop_event
    stop_event = threading.Event()
    def start_midi():
        while not stop_event.is_set():
            for msg in in_port.iter_pending():
                if stop_event.is_set():  # Check if we should stop
                    return
                if msg.type in ["note_on", "control_change", "pitchwheel"]:
                    if msg.type == "note_on":
                        voice = "voice_" + str(voice_seq.next())
                        mmm_audio.send_floats(voice+".note", [midicps(msg.note), msg.velocity / 127.0])  # note freq and velocity scaled 0 to 1
                    elif msg.type == "control_change":
                        if msg.control == 34:  # Mod wheel
                            # on the desired cc, scale the value exponentially from 100 to 4000
                            # it is best practice to scale midi cc values in the host, rather than in the audio engine
                            mmm_audio.send_float("filt_freq", linexp(msg.value, 0, 127, 100, 4000))
                    elif msg.type == "pitchwheel":
                        mmm_audio.send_float("bend_mul", linlin(msg.pitch, -8192, 8191, 0.9375, 1.0625))
            time.sleep(0.01)
    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=False)
    midi_thread.start()

if __name__ == "__main__":
    main()