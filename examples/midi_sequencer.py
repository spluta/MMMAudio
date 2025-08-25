from mmm_src.MMMAudio import MMMAudio

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="Midi_Sequencer", package_name="examples")
mmm_audio.start_audio()


# start the midi thread for the current port

import mido
import time
import threading

# find your midi devices
mido.get_input_names()

# open your midi device - you may need to change the device name
in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

def start_midi():
    while True:
        for msg in in_port.iter_pending():
            # print(msg)
            mmm_audio.send_midi(msg)
        time.sleep(0.01) # Small delay to prevent busy-waiting

midi_thread = threading.Thread(target=start_midi, daemon=True)
# once you start the midi_thread, it should register note_on, note_off, cc, etc from your device and send them to mmm
midi_thread.start()


# the scheduler can also sequence notes
from mmm_src.Patterns import * # some sc style patterns
import numpy as np
import asyncio
import librosa

scheduler = mmm_audio.scheduler

async def trig_synth(wait):
    """A counter coroutine"""
    count_to = np.random.choice([7, 11, 13, 17]).item()
    mult_seq = Pseq(list(range(1, count_to + 1)))
    fund_seq = Pxrand([36, 37, 43, 42])
    i = 0
    fund = librosa.midi_to_hz(fund_seq.next())
    while True:
        pitch = mult_seq.next() * fund
        mmm_audio.send_msg("t_trig", 1.0)
        mmm_audio.send_msg("trig_seq_freq", pitch)
        await asyncio.sleep(wait)
        i = (i + 1) % count_to
        if i == 0:
            fund = librosa.midi_to_hz(fund_seq.next())
            count_to = np.random.choice([7, 11, 13, 17]).item()
            print("count to", count_to)
            mult_seq = Pseq(list(range(1, count_to + 1)))

scheduler.sched(trig_synth(0.1))

scheduler.stop_routs()

mmm_audio.stop()        
mmm_audio.start()
