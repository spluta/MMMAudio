"""
Demonstrates how to use the PitchShift grain-based pitch shifter with microphone input.

This example assumes you have a microphone input device set up and selected as the default input device on your system.

A couple of settings in the .py file are important: 

- num_input_channels: This can be set to any value, but it should be at least as high as the input channel you want to use.
- in_chan: This should be set to the input channel number of your microphone input source (0-indexed).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from mmm_python import *

def main():

    mmm_audio = MMMAudio(128, num_input_channels = 12, graph_name="PitchShiftExample", package_name="examples")
    mmm_audio.send_int("in_chan", 0) # set input channel to your input source
    mmm_audio.start_audio() # start the audio thread - or restart it where it left off

    app = QApplication([])

    # Create the main window
    window = QWidget()
    window.setWindowTitle("Pitch Shift Controller")
    window.resize(300, 100)
    # stop audio when window is closed
    window.closeEvent = lambda event: (MMMAudio.exit_all(), event.accept())

    # Create layout
    layout = QVBoxLayout()

    pitch_shift_slider = Handle("pitch_shift",ControlSpec(0.25, 4.0, 0.5), 1, callback=lambda v: mmm_audio.send_float("pitch_shift", v), run_callback_on_init=True)
    layout.addWidget(pitch_shift_slider)

    grain_dur_slider = Handle("grain_dur", ControlSpec(0.1, 1.0, 1), 0.4, callback=lambda v: mmm_audio.send_float("grain_dur", v))
    layout.addWidget(grain_dur_slider)

    pitch_dispersion_slider = Handle("pitch_dispersion", ControlSpec(0.0, 1.0, 1), 0, callback=lambda v: mmm_audio.send_float("pitch_dispersion", v), run_callback_on_init=True)
    layout.addWidget(pitch_dispersion_slider)

    time_dispersion_slider = Handle("time_dispersion", ControlSpec(0.0, 1.0, 1), 0, callback=lambda v: mmm_audio.send_float("time_dispersion", v), run_callback_on_init=True)
    layout.addWidget(time_dispersion_slider)

    added_delay_low_slider = Handle("added_delay_low", ControlSpec(0.0, 2.0, 1), 0, callback=lambda v: mmm_audio.send_float("added_delay_low", v), run_callback_on_init=True)
    layout.addWidget(added_delay_low_slider)

    added_delay_high_slider = Handle("added_delay_high", ControlSpec(0.0, 2.0, 1), 0, callback=lambda v: mmm_audio.send_float("added_delay_high", v), run_callback_on_init=True)
    layout.addWidget(added_delay_high_slider)

    overlaps_slider = Handle("overlaps", ControlSpec(1, 16, 1), 4, callback=lambda v: mmm_audio.send_int("overlaps", int(v)), run_callback_on_init=True)
    layout.addWidget(overlaps_slider)

    fb_perc_slider = Handle("feedback", ControlSpec(0.0, 1.0, 1), 0, callback=lambda v: mmm_audio.send_float("fb_perc", v), run_callback_on_init=True)
    layout.addWidget(fb_perc_slider)

    window.setLayout(layout)
    window.show()
    app.exec()

if __name__ == "__main__":
    main()