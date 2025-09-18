# PlayBuf

:::examples.PlayBuf

```python

from mmm_src.MMMAudio import MMMAudio
import asyncio
import threading


mmm_audio = MMMAudio(128, graph_name="PlayBuf_Graph", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off

# this example uses open sound control to control PlayBuf's playback speed and VAMoogFilter's cutoff frequency
# there is a simple touchosc patch provided for control
# it is looking for /fader1 and /fader2 on port 5005; these can be adjusted
# Start the OSC server on its own thread
# this is a bug, but this thread has to start after audio or audio won't start
thread = threading.Thread(target=asyncio.run, args=(mmm_audio.start_osc_server(5005),), daemon=True)
thread.start()

# if touch_osc isn't available you can also send the messages directly
mmm_audio.send_msg("/fader1", 0.5) # fader value is mapped exponentially between 0.25 and 4
mmm_audio.send_msg("/fader1", 0.25) 

mmm_audio.send_msg("/fader2", 0.5) # fader value is mapped exponentially between 20 and 20000
mmm_audio.send_msg("/fader2", 1) 

mmm_audio.stop_audio() # stop/pause the audio thread

```