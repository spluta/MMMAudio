import sys
from pathlib import Path

# This example is able to run by pressing the "play" button in VSCode
# that executes the whole file.
# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent))

from mmm_utils.GUI import Handle, ControlSpec
from mmm_src.MMMAudio import MMMAudio
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QCheckBox

# instantiate and load the graph
mmm_audio = MMMAudio(128, graph_name="BenjolinExample", package_name="examples")
mmm_audio.start_audio()

app = QApplication([])

# Create the main window
window = QWidget()
window.setWindowTitle("Feedback Delay Controller")
window.resize(300, 100)
# stop audio when window is closed
window.closeEvent = lambda event: (mmm_audio.stop_audio(), event.accept())

# Create layout
layout = QVBoxLayout()

def add_handle(name: str, min: float, max: float, exp: float, default: float):
    # make the slider
    slider = Handle(name, ControlSpec(min, max, exp), default, callback=lambda v: mmm_audio.send_msg(name, v))
    # add it to the layout
    layout.addWidget(slider)
    # send the default value to the graph
    mmm_audio.send_msg(name, default)

add_handle("freq1", 20, 14000.0, 0.25, 100)
add_handle("freq2", 0.1, 14000.0, 0.25, 5)
add_handle("scale", 0, 1.0, 1, 0.1)
add_handle("rungler1", 0, 1.0, 1, 0.1)
add_handle("rungler2", 0, 1.0, 1, 0.1)
add_handle("runglerFiltMul", 0, 1.0, 1.0, 0.5)
add_handle("loop", 0, 1.0, 1, 0.1)
add_handle("filterFreq", 20, 20000, 0.25, 3000)
add_handle("q", 0.1, 10, 0.5, 1.0)
add_handle("gain", 0.0, 2.0, 1, 1.0)
add_handle("filterType", 0, 8, 1.0, 0.0)
add_handle("outSignalL", 0, 6, 1.0, 1.0)
add_handle("outSignalR", 0, 6, 1.0, 3.0)

# Set the layout for the main window
window.setLayout(layout)

# Show the window
window.show()

# Start the application's event loop
app.exec()