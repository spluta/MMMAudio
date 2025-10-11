from mmm_src.MMMAudio import MMMAudio


# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="TestASR", package_name="tests")
# mmm_audio.start_audio() 


mmm_audio.start_audio()

mmm_audio.send_msg("curve", -1.0)

# this program is looking for midi note_on and note_off from note 48, so we prepare the keyboard to send messages to mmm_audio:
if True:
    import mido
    import time
    import threading
    from mmm_utils.functions import *

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
                    mmm_audio.send_msg("gate", 1)
                elif msg.type == "note_off" and msg.note == 48:
                    mmm_audio.send_msg("gate", 0)
            time.sleep(0.01)

    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=True)
    midi_thread.start()

# To stop the thread:
stop_event.set()