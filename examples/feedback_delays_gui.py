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

mmm_audio = MMMAudio(128, graph_name="FeedbackDelaysGUI", package_name="examples")

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

gatebutton = QCheckBox("play")
gatebutton.setChecked(True)
gatebutton.stateChanged.connect(lambda state: mmm_audio.send_msg("play", 1.0 if state == 2 else 0.0))
layout.addWidget(gatebutton)

gatebutton = QCheckBox("delay-input")
gatebutton.setChecked(True)
gatebutton.stateChanged.connect(lambda state: mmm_audio.send_msg("delay-input", 1.0 if state == 2 else 0.0))
layout.addWidget(gatebutton)

# Create a slider
delaytimeslider = Handle("delay time",ControlSpec(0, 1.0, 0.5), 0.5, callback=lambda v: mmm_audio.send_msg("delay_time", v))
layout.addWidget(delaytimeslider)

feedbackslider = Handle("feedback",ControlSpec(-130, -0.1, 4), -6, callback=lambda v: mmm_audio.send_msg("feedback", v))
layout.addWidget(feedbackslider)

freqslider = Handle("ffreq",ControlSpec(20, 20000, 0.5), 8000, callback=lambda v: mmm_audio.send_msg("ffreq", v))
layout.addWidget(freqslider)

qslider = Handle("q",ControlSpec(0.1, 10, 0.5), 1.0, callback=lambda v: mmm_audio.send_msg("q", v))
layout.addWidget(qslider)

mixslider = Handle("mix",ControlSpec(0.0, 1.0, 2), 0.2, callback=lambda v: mmm_audio.send_msg("mix", v))
layout.addWidget(mixslider)

gatebutton = QCheckBox("main")
gatebutton.setChecked(True)
gatebutton.stateChanged.connect(lambda state: mmm_audio.send_msg("main", 1.0 if state == 2 else 0.0))
layout.addWidget(gatebutton)

# Set the layout for the main window
window.setLayout(layout)

# Show the window
window.show()

# Start the application's event loop
app.exec()