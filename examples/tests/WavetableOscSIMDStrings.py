"""Example of a wavetable oscillator using custom wavetables loaded from files.

This example uses SIMDBuffer instead of Buffer to load the wavetable. This allows for more efficient processing for wavetables with a small number of channels (2-8), where the number of channels is known ahead of time, but it should not be used with wavetables that have a large number of waveforms.

This example also uses Mojo-side Poly vs PVoiceAllocator.
"""

import sys
from pathlib import Path

# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
from srcpy import *

def main():
    mmm_audio = MMMAudio(128, graph_name="WavetableOscSIMDStrings", package_name="examples.tests")
    mmm_audio.start_audio() 

    import threading, mido, time

    # open your midi device - you may need to change the device name
    in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

    # PolyPal correctly formats messages to be sent to a Synth that uses a Poly object
    poly_pal = PolyPal(mmm_audio, "poly", 10)

    # just intonation ratios for a chromatic scale based on C major
    just_offset = [
    0.0,       # C
    0.1173,    # C#
    0.0391,    # D
    0.1564,    # Eb
   -0.1369,    # E
   -0.0196,    # F
   -0.0978,    # F#
    0.0196,    # G
    0.1369,    # Ab
   -0.1564,    # A
    0.1760,    # Bb
   -0.1173     # B
    ]

    # Create stop event
    global stop_event
    stop_event = threading.Event()
    def start_midi():
        while not stop_event.is_set():
            for msg in in_port.iter_pending():
                if stop_event.is_set():  # Check if we should stop
                    return

                if msg.type in ["note_on", "note_off", "control_change"]:
                    if msg.type == "note_on":
                        midi_note = msg.note+just_offset[msg.note % 12]
                        print(f"Note On: {midi_note} Velocity: {msg.velocity}")
                        poly_pal.send_floats([midi_note, (msg.velocity)])  
                    if msg.type == "note_off":
                        midi_note = msg.note+just_offset[msg.note % 12]
                        print(f"Note Off: {midi_note} Velocity: {msg.velocity}")
                        poly_pal.send_floats([midi_note, 0.0])  
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

if __name__ == "__main__":
    main()