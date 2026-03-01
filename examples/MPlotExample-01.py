from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QSizePolicy
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *
from umap import UMAP
from sklearn.neighbors import KDTree
import pickle
import librosa

with open("analysis.pkl", "rb") as f:
    d = pickle.load(f)

y, sr = librosa.load(d["path"], sr=None)
data = d["data"]
slice_points = d["slice_points"]

data_umap = UMAP(n_components=2,learning_rate=0.1,min_dist=0.7,n_epochs=200).fit_transform(data)

kdtree = KDTree(data_umap)

ma = MMMAudio(128,graph_name="MPlotExample", package_name="examples")
ma.start_audio()

ma.send_string("load_sound", d["path"])

prev = None

def gui():
    def get_nearest(view, x, y, button, is_dragging, key, dblclick, step):
        global prev
        if step is None:
            dist, idx = kdtree.query([[x, y]], k=1)
            nearest = int(idx[0][0])
            if nearest != prev:
                prev = nearest
                start = slice_points[nearest]
                num = slice_points[nearest+1] - start
                
                view.highlight_index(nearest)
                
                waveform_win.highlight(start, num)
                
                ma.send_ints("play_data", [start, num])
                print(f"x: {x:.2f}, y: {y:.2f}")
                print(f"Nearest idx: {idx[0][0]}, dist: {dist[0][0]:.4f}")

    app = QApplication([])
    main = QMainWindow()
    root = QWidget()
    layout = QVBoxLayout(root)

    win = MPlot(data_umap, mouse_callback=get_nearest,xlabel="UMAP 1", ylabel="UMAP 2")
    waveform_win = MWaveform(y, d["slice_points"])
    waveform_win.setFixedHeight(220)
    waveform_win.setSizePolicy(QSizePolicy.Preferred, QSizePolicy.Fixed)

    layout.addWidget(win)
    layout.addWidget(waveform_win)
    layout.setStretch(0, 1)
    layout.setStretch(1, 0)
    main.setCentralWidget(root)

    def shutdown_audio():
        ma.stop_audio()

    app.aboutToQuit.connect(shutdown_audio)
    main.closeEvent = lambda event: (shutdown_audio(), event.accept())

    main.resize(900, 850)
    main.show()
    sys.exit(app.exec())

gui()