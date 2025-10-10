# import threading

# class MidiThread:
#     def __init__(self, midi_file, mmm_audio, midi_func=None):
#         self.mmm_audio = mmm_audio
#         self.stop_event = threading.Event()
#         self.thread = threading.Thread(target=self.run)
#         self.thread.start()

#         self.default_midi_func = lambda msg: print(f"Received MIDI message: {msg}")

#         self.midi_func = midi_func if midi_func else self.default_midi_func

#     def set_func(self, func):
#         self.midi_func = func

#     def start(self):
#         self.stop_event.clear()
#         if not self.thread.is_alive():
#             self.thread = threading.Thread(target=self.run)
#             self.thread.start()

#     def stop(self):
#         self.stop_event.set()
#         self.thread.join()