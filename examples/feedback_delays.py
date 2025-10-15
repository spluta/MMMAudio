import sys
from pathlib import Path

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).parent.parent))

from mmm_utils.GUI import Handle, ControlSpec
from mmm_src.MMMAudio import MMMAudio
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QCheckBox

mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off
# mmm_audio.stop_audio() # stop/pause the audio thread                

app = QApplication([])

# Create the main window
window = QWidget()
window.setWindowTitle("Feedback Delay Controller")
window.resize(300, 100)
window.closeEvent = lambda event: (mmm_audio.stop_audio(), event.accept())

# Create layout
layout = QVBoxLayout()

# Create a slider
delaytimeslider = Handle("delay time",ControlSpec(0, 1.0, 0.5), 0, callback=lambda v: mmm_audio.send_msg("delay_time", v))
layout.addWidget(delaytimeslider)

feedbackslider = Handle("feedback",ControlSpec(0, 0.99, 0.5), 0, callback=lambda v: mmm_audio.send_msg("feedback", v))
layout.addWidget(feedbackslider)

freqslider = Handle("ffreq",ControlSpec(20, 20000, 0.5), 8000, callback=lambda v: mmm_audio.send_msg("ffreq", v))
layout.addWidget(freqslider)

gatebutton = QCheckBox("gate")
gatebutton.setChecked(False)
gatebutton.stateChanged.connect(lambda state: mmm_audio.send_msg("gate", 1.0 if state == 2 else 0.0))
layout.addWidget(gatebutton)

# Set the layout for the main window
window.setLayout(layout)

# Show the window
window.show()

# Start the application's event loop
app.exec()