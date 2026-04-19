import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from mmm_python import *

def run_gui():
    mmm_audio = MMMAudio(128, graph_name="TestLFSRNoise", package_name="examples.tests")
    mmm_audio.start_audio()
    app = QApplication([])
    window = QWidget()
    window.setWindowTitle("TestLFSRNoise")
    window.resize(300, 400)

    layout = QVBoxLayout()

    def add_handle(name, min, max, exp, default, resolution=1000):
        slider = Handle(name, ControlSpec(min, max, exp), default, callback=lambda v: mmm_audio.send_float(name, v), resolution=resolution, run_callback_on_init=True)
        layout.addWidget(slider)
        mmm_audio.send_float(name, default)

    add_handle("freq1", 1.0, 20000.0, 0.25, 1000.0)
    add_handle("freq2", 1.0, 20000.0, 0.25, 1100.0)
    add_handle("gain1", 0.0, 1.0, 1, 0.2)
    add_handle("gain2", 0.0, 1.0, 1, 0.2)

    def add_handle(name, min, max, exp, default, resolution=1000):
        slider = Handle(name, ControlSpec(min, max, exp), default, callback=lambda v: mmm_audio.send_int(name, v), resolution=resolution, run_callback_on_init=True)
        layout.addWidget(slider)
        mmm_audio.send_float(name, default)

    add_handle("width1", 3.0, 32.0, 1, 15.0, resolution=29)
    add_handle("width2", 3.0, 32.0, 1, 4.0, resolution=29)


    window.setLayout(layout)
    window.closeEvent = lambda event: (MMMAudio.exit_all(), event.accept())
    window.show()
    window.raise_()
    app.exec()

if __name__ == "__main__":
    run_gui()