from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="TestASR", package_name="examples.tests")
mmm_audio.start_audio()

mmm_audio.send_floats("curves", [4.0, -4.0])  # set the curves to logarithmic attack and exponential decay

# this program is looking for midi note_on and note_off from note 48, so we prepare the keyboard to send messages to mmm_audio:
if True:
    import mido
    import time
    import threading
    from mmm_python.python_utils import *

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

                if msg.type == "note_on":
                    mmm_audio.send_bool("gate", True)
                elif msg.type == "note_off":
                    mmm_audio.send_bool("gate", False)
            time.sleep(0.01)

    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=False)
    midi_thread.start()

# After you've pressed a MIDI key to test it: stop the thread:
stop_event.set()