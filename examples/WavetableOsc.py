"""Example of a wavetable oscillator using custom wavetables loaded from files.

You can load your own wavetable files by sending a string message to the "load_file" parameter with the full path to the wavetable file.

MMM_Audio can load commercial .wav files, designed for Vital or Serum, as wavetables. The wavetable should be a single channel audio file made up of one or more cycles of a waveform, each a power of 2 in length. The wavetable will be looped to create the oscillator waveform.

Also demonstrates how to use the PVoiceAllocator class to manage multiple voices for polyphonic MIDI input.
"""

from srcpy import *
src_mojo = MMMAudio(128, graph_name="WavetableOsc", package_name="examples")
src_mojo.start_audio() 

# load a different wavetable if you like - these are just example paths - change to your own files
# if the number of instances of the wave found in the wavetable file is different than the default 256, you may need to change the "wavetables_per_channel" parameter
src_mojo.send_int("wavetables_per_channel", 128) # set this to the number of waveforms in your wavetable file

src_mojo.send_string("load_file", "'/Users/ted/dev/BVKER - Custom Wavetables/Growl/Growl 10.wav'")
src_mojo.send_string("load_file", "'/Users/ted/dev/BVKER - Custom Wavetables/Growl/Growl 11.wav'")
src_mojo.send_string("load_file", "'/Users/ted/dev/BVKER - Custom Wavetables/Growl/Growl 12.wav'")
src_mojo.send_string("load_file", "'/Users/ted/dev/BVKER - Custom Wavetables/Growl/Growl 13.wav'")
src_mojo.send_string("load_file", "'/Users/ted/dev/BVKER - Custom Wavetables/Growl/Growl 14.wav'")
src_mojo.send_string("load_file", "'/Users/ted/dev/BVKER - Custom Wavetables/Growl/Growl 15.wav'")

if True:
    import threading
    import mido
    import time
    from srcpy.functions import linexp, linlin, midicps, cpsmidi
    from srcpy.Patterns import PVoiceAllocator

    # find your midi devices
    print(mido.get_input_names())

    # open your midi device - you may need to change the device name
    in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

    voice_allocator = PVoiceAllocator(8)

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
                        voice = voice_allocator.get_free_voice(msg.note)
                        if voice == -1:
                            print("No free voice available")
                            continue
                        else:
                            voice_msg = "voice_" + str(voice)
                            print(f"Note On: {msg.note} Velocity: {msg.velocity} Voice: {voice}")
                            src_mojo.send_float(voice_msg +".freq", midicps(msg.note))  # note freq and velocity scaled 0 to 1
                            src_mojo.send_bool(voice_msg +".gate", True)  # note freq and velocity scaled 0 to 1
                    if msg.type == "note_off":
                        found, voice = voice_allocator.release_voice(msg.note)
                        if found:
                            voice_msg = "voice_" + str(voice)
                            print(f"Note Off: {msg.note} Voice: {voice}")
                            src_mojo.send_bool(voice_msg +".gate", False)  # note freq and velocity scaled 0 to 1
                    if msg.type == "control_change":
                        print(f"Control Change: {msg.control} Value: {msg.value}")
                        # Example: map CC 1 to wubb_rate of all voices
                        if msg.control == 1:
                            wubb_rate = linexp(msg.value, 0, 127, 0.1, 10.0)
                            for i in range(8):
                                voice_msg = "voice_" + str(i)
                                src_mojo.send_float(voice_msg +".wubb_rate", wubb_rate)
                        if msg.control == 33:
                            src_mojo.send_float("filter_cutoff", linexp(msg.value, 0, 127, 20.0, 20000.0))
                        if msg.control == 34:
                            src_mojo.send_float("filter_resonance", linexp(msg.value, 0, 127, 0.1, 1.0))

            time.sleep(0.01)
    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=False)
    midi_thread.start()

