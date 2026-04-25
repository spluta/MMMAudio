"""
Shows how to load and audio buffer from a sound file and play it using the Play UGen. 

This example uses open sound control to control Play's playback speed and VAMoogFilter's cutoff frequency. These can be sent from a simple touchosc patch or any other OSC controller. A touchosc patch is provided for control.

This example is able to run by pressing the "play" button in VSCode or compiling and running the whole file on the command line.
"""

import sys
from pathlib import Path

# This example is able to run by pressing the "play" button in VSCode
# that executes the whole file.
# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmmaudio import *
from PySide6.QtWidgets import QWidget, QVBoxLayout, QSlider, QPushButton, QLabel, QLineEdit, QFileDialog
from PySide6.QtCore import Qt

def open_save_dialog(parent: QWidget) -> str:
    """Opens a save file dialog and returns the chosen filename."""
    filename, selected_filter = QFileDialog.getSaveFileName(parent, "Save File", "", "WAV Files (*.wav)")
    if filename:
        print(f"File chosen: {filename}")
        return filename
    else:
        print("Dialog was cancelled")
        return None
    
def open_load_dialog(parent: QWidget) -> str:
    """Opens a load file dialog and returns the chosen filename."""
    filename, _ = QFileDialog.getOpenFileName(parent, "Load File", "", "WAV Files (*.wav)")
    if filename:
        print(f"File chosen: {filename}")
        return filename
    else:
        print("Dialog was cancelled")
        return None


def main():
    mmm_audio = MMMAudio(128, graph_name="PlayRecExample", package_name="examples")

    mmm_audio.start_audio() # start the audio thread - or restart it where it left off    

    app = QApplication(sys.argv)
    # Create the main window
    window = QWidget()
    window.setWindowTitle("Play Example")
    window.resize(300, 100)
    # stop audio when window is closed
    window.closeEvent = lambda event: (MMMAudio.exit_all(), event.accept())

    layout = QVBoxLayout()
    handle = Handle("PlayRate", ControlSpec(0.25,4,0.5), 1, lambda v: mmm_audio.send_float("play_rate", v), run_callback_on_init=True)
    layout.addWidget(handle)

    handle = Handle("LPFFrequency", ControlSpec(100, 20000, 0.5), 20000, 
                    lambda v: mmm_audio.send_float("lpf_freq", v), run_callback_on_init=True)
    layout.addWidget(handle)
    
    # Load Button
    load_button = QPushButton("Load Audio File")
    load_button.clicked.connect(lambda: mmm_audio.send_string("load_buffer", open_load_dialog(window)))
    layout.addWidget(load_button)
    
    # Save Button
    rec_button = QPushButton("Start Recording")
    rec_button.clicked.connect(lambda: mmm_audio.send_trig("start_recording"))
    layout.addWidget(rec_button)
    # Save Button
    stop_button = QPushButton("Stop Recording")
    stop_button.clicked.connect(lambda: mmm_audio.send_trig("stop_recording"))
    layout.addWidget(stop_button)
    
    # Save Button
    save_button = QPushButton("Save Audio File")
    save_button.clicked.connect(lambda: mmm_audio.send_string("save_buffer", open_save_dialog(window)))
    layout.addWidget(save_button)
    
    window.setLayout(layout)
    
    window.show()

    
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
