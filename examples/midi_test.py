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
        time.sleep(0.01)

# Start the thread
midi_thread = threading.Thread(target=start_midi, daemon=False)
midi_thread.start()