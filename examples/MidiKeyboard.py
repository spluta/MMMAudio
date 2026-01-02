if True:
    from mmm_python.MMMAudio import MMMAudio

    # instantiate and load the graph - notice we are using the MidiSequencer graph here (the same as in the MidiSequencer example)
    mmm_audio = MMMAudio(128, graph_name="MidiSequencer", package_name="examples")
    mmm_audio.start_audio()

# this next chunk of code is all about using a midi keyboard to control the synth---------------

def midi_func():
    import threading
    import mido
    import time
    from mmm_python.functions import linexp, linlin, midicps, cpsmidi
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
                        print(f"Note On: {msg.note} Velocity: {msg.velocity} Voice: {voice}")
                        mmm_audio.send_floats(voice +".note", [midicps(msg.note), msg.velocity / 127.0])  # note freq and velocity scaled 0 to 1

                    elif msg.type == "control_change":
                        if msg.control == 34:  # Mod wheel
                            # on the desired cc, scale the value exponentially from 100 to 4000
                            # it is best practice to scale midi cc values in the host, rather than in the audio engine
                            mmm_audio.send_float("filt_freq", linexp(msg.value, 0, 127, 100, 4000))
                    elif msg.type == "pitchwheel":
                        mmm_audio.send_float("bend_mul", linlin(msg.pitch, -8192, 8191, 0.9375, 1.0625))
            time.sleep(0.01)

    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=True)
    midi_thread.start()

# run the midi function to start listening to midi
midi_func()

# To stop the midi thread defined above:
stop_event.set()
