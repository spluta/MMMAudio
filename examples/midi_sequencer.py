if True:
    from mmm_src.MMMAudio import MMMAudio

    # instantiate and load the graph
    mmm_audio = MMMAudio(128, graph_name="Midi_Sequencer", package_name="examples")
    mmm_audio.start_audio()

# this next chunk of code is all about using a midi keyboard to control the synth---------------

# the python host grabs the midi and sends the midi messages to the mojo audio engine

def midi_func():
    import threading
    import mido
    import time
    from mmm_utils.functions import linexp, linlin

    # find your midi devices
    mido.get_input_names()

    # open your midi device - you may need to change the device name
    in_port = mido.open_input('Oxygen Pro Mini USB MIDI')

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
                        msg2 = [1, msg.note, msg.velocity]
                    
                    elif msg.type == "control_change":
                        if msg.control == 34:  # Mod wheel
                            # on the desired cc, scale the value exponentially from 100 to 4000
                            # it is best practice to scale midi cc values in the host, rather than in the audio engine
                            msg2 = [msg.channel, msg.control, linexp(msg.value, 0, 127, 100, 4000)]
                        else:
                            msg2 = [msg.channel, msg.control, msg.value]
                    elif msg.type == "pitchwheel":
                        msg2 = [msg.channel, linlin(msg.pitch, -8192, 8191, 0.9375, 1.0625)]
                    mmm_audio.send_msg(msg.type, *msg2)
            time.sleep(0.01)

    # Start the thread
    midi_thread = threading.Thread(target=start_midi, daemon=True)
    midi_thread.start()

midi_func()

# To stop the midi thread defined above:
stop_event.set()


# this chunk of code shows how to use the sequencer to trigger notes in the mmm_audio engine

# the scheduler can also sequence notes
from mmm_src.Patterns import Pseq, Pxrand
import numpy as np
import asyncio
from mmm_utils.functions import midicps, cpsmidi

global scheduler
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

rout = scheduler.sched(trig_synth(0.1))
rout.cancel() # stop just this routine

# stop all routines
scheduler.stop_routs() # you can also stop the routines with ctl-C in the terminal

mmm_audio.stop_audio()
mmm_audio.start_audio()
