if True:
    from mmm_src.MMMAudio import *
    list_audio_devices()

    in_device = "Fireface UFX+ (24082112)"
    out_device = "Fireface UFX+ (24082112)"

    # in_device = "MacBook Pro Microphone"
    # out_device = "External Headphones"


    # instantiate and load the graph
    mmm_audio = MMMAudio(128, num_input_channels=12, num_output_channels=2, in_device=in_device, out_device=out_device, graph_name="Record", package_name="examples")

    # the default input channel (in the Record_Synth) is 0, but you can change it
    mmm_audio.send_msg("set_input_chan", 8) 
    mmm_audio.start_audio() 


mmm_audio.send_msg("print_inputs")

mmm_audio.send_msg("start_recording")
mmm_audio.send_msg("stop_recording")

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
                    mmm_audio.send_msg("start_recording")
                elif msg.type == "note_off" and msg.note == 48:
                    mmm_audio.send_msg("stop_recording")
            time.sleep(0.01)

    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=True)
    midi_thread.start()

# To stop the thread:
stop_event.set()

