from mmm_src.MMMAudio import MMMAudio 

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="Midi_Sequencer", package_name="examples")
mmm_audio.start_audio()

# this next chunk of code is all about using a midi keyboard to control the synth---------------

# the python host grabs the midi and sends the midi messages to the mojo audio engine

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

            # convert the mido message to a list of floats for mojo
            msg2 = [msg.channel, msg.note, msg.velocity] if msg.type == "note_on" else \
                  [msg.channel, msg.note, msg.velocity] if msg.type == "note_off" else \
                  [msg.channel, msg.control, linexp(msg.value, 0, 127, 100.0, 4000.0)] if msg.type == "control_change" else \
                  [linlin(msg.pitch, -8192, 8191, 0.9375, 1.0625)] if msg.type == "pitchwheel" else None

            print("Sending MIDI message to MMMAudio:", msg.type, msg2)
            if msg2:
                mmm_audio.send_msg(msg.type, msg2)
        time.sleep(0.01)

# Start the thread
midi_thread = threading.Thread(target=start_midi, daemon=True)
midi_thread.start()

# To stop the thread:
stop_event.set()
# midi_thread.join(timeout=1.0)  # Wait up to 1 second for clean shutdown

# this chunk of code shows how to use the sequencer to trigger notes in the mmm_audio engine

# the scheduler can also sequence notes
from mmm_src.Patterns import * # some sc style patterns
import numpy as np
import asyncio
from mmm_utils.functions import *

scheduler = mmm_audio.scheduler

async def trig_synth(wait):
    """A counter coroutine"""
    count_to = np.random.choice([7, 11, 13, 17]).item()
    mult_seq = Pseq(list(range(1, count_to + 1)))
    fund_seq = Pxrand([36, 37, 43, 42])
    i = 0
    fund = midicps(fund_seq.next())
    while True:
        note = cpsmidi(mult_seq.next() * fund)
        mmm_audio.send_msg("note_on", 0, note, 100)
        await asyncio.sleep(wait)
        i = (i + 1) % count_to
        if i == 0:
            fund = midicps(fund_seq.next())
            count_to = np.random.choice([7, 11, 13, 17]).item()
            mult_seq = Pseq(list(range(1, count_to + 1)))

scheduler.sched(trig_synth(0.1))

scheduler.stop_routs()

mmm_audio.stop_audio()
mmm_audio.start_audio()
