import sys
from pathlib import Path

# This example is able to run by pressing the "play" button in VSCode
# that executes the whole file.
# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent))

from mmm_src.MMMAudio import MMMAudio
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton


mmm_audio = MMMAudio(256, graph_name="SpectralFreezeExample", package_name="examples")
mmm_audio.start_audio()

app = QApplication([])

# Create the main window
window = QWidget()
window.setWindowTitle("Spectral Freeze Controller")
window.resize(100, 100)
# stop audio when window is closed
window.closeEvent = lambda event: (mmm_audio.stop_audio(), event.accept())

# Create layout
layout = QVBoxLayout()

gatebutton = QPushButton("Freeze Gate")
gatebutton.setCheckable(True)
gatebutton.setChecked(False)
gatebutton.clicked.connect(lambda checked: mmm_audio.send_bool("freeze_gate", checked))
layout.addWidget(gatebutton)
window.setLayout(layout)
window.show()
app.exec()
