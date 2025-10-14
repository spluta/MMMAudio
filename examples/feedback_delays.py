"""use the mouse to control an overdriven feedback delay"""

from mmm_src.MMMAudio import MMMAudio
from PySide6.QtWidgets import QApplication, QWidget, QVBoxLayout, QSlider, QPushButton, QMessageBox
from PySide6.QtCore import Qt

mmm_audio = MMMAudio(128, graph_name="FeedbackDelays", package_name="examples")

mmm_audio.start_audio() # start the audio thread - or restart it where it left off
mmm_audio.stop_audio() # stop/pause the audio thread                


# Create the application
app = QApplication()

# Create the main window
window = QWidget()
window.setWindowTitle("Feedback Delay Controller")
window.resize(300, 100)

# Create layout
layout = QVBoxLayout()

# Create a slider
slider = QSlider(Qt.Horizontal)
slider.setMinimum(0)
slider.setMaximum(100)
slider.setValue(50)  # Set initial value
layout.addWidget(slider)

# Create a button with a lambda function as the callback
button = QPushButton("Show Slider Value")
button.clicked.connect(lambda: show_slider_value(slider.value()))
layout.addWidget(button)

# Set the layout for the main window
window.setLayout(layout)

# Show the window
window.show()