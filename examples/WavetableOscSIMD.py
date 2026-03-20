"""Example of a wavetable oscillator using custom wavetables loaded from files.

This example uses SIMDBuffer instead of Buffer to load the wavetable. This allows for more efficient processing for wavetables with a small number of channels (2-8), where the number of channels is known ahead of time, but it should not be used with wavetables that have a large number of waveforms.

This example also uses Mojo-side Poly vs PVoiceAllocator.
"""

from mmm_python import *
mmm_audio = MMMAudio(128, graph_name="WavetableOscSIMD", package_name="examples")
mmm_audio.start_audio() 


if True:
    import threading, mido, time

    # find your midi devices
    print(mido.get_input_names())

    # open your midi device - you may need to change the device name
    in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

    message_seq = Pseq(list(range(10))) # up to 10 messages per block

    # Create stop event
    global stop_event
    stop_event = threading.Event()
    def start_midi():
        while not stop_event.is_set():
            for msg in in_port.iter_pending():
                if stop_event.is_set():  # Check if we should stop
                    return

                if msg.type in ["note_on", "note_off", "control_change"]:
                    print(msg)
                    if msg.type == "note_on":
                        msg_num = message_seq.next() 
                        print(f"Note On: {msg.note} Velocity: {msg.velocity}")
                        mmm_audio.send_ints("note"+str(msg_num), [msg.note, msg.velocity])  
                    if msg.type == "note_off":
                        msg_num = message_seq.next() 
                        print(f"Note Off: {msg.note} Velocity: {msg.velocity}")
                        mmm_audio.send_ints("note"+str(msg_num), [msg.note, 0])  
                    if msg.type == "control_change":
                        print(f"Control Change: {msg.control} Value: {msg.value}")
                        # Example: map CC 1 to wubb_rate of all voices
                        if msg.control == 1:
                            wubb_rate = linexp(msg.value, 0, 127, 0.1, 10.0)
                            mmm_audio.send_float("wubb_rate", wubb_rate)
                        if msg.control == 33:
                            mmm_audio.send_float("filter_cutoff", linexp(msg.value, 0, 127, 20.0, 20000.0))
                        if msg.control == 34:
                            mmm_audio.send_float("filter_resonance", linexp(msg.value, 0, 127, 0.1, 1.0))

            time.sleep(0.01)
    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=False)
    midi_thread.start()
