from mmm_python import *

mmm_audio = MMMAudio(128, graph_name="TestLFSRNoise", package_name="examples.tests")
mmm_audio.start_audio()

app = QApplication([])

def run_gui():
    window = QWidget()
    window.setWindowTitle("TestLFSRNoise")
    window.resize(300, 400)

    layout = QVBoxLayout()

    def add_handle(name, min, max, exp, default, resolution=1000):
        slider = Handle(name, ControlSpec(min, max, exp), default, callback=lambda v: mmm_audio.send_float(name, v), resolution=resolution)
        layout.addWidget(slider)
        mmm_audio.send_float(name, default)

    add_handle("freq", 1.0, 20000.0, 0.25, 1000.0)
    add_handle("gain", 0.0, 1.0, 1, 0.2)

    width_slider = Handle("width", ControlSpec(3.0, 32.0, 1), 15.0, callback=lambda v: mmm_audio.send_float("width", float(round(v))), resolution=29)
    layout.addWidget(width_slider)
    mmm_audio.send_float("width", 15.0)

    window.setLayout(layout)
    window.show()
    window.raise_()
    app.exec()

run_gui()

mmm_audio.stop_audio()