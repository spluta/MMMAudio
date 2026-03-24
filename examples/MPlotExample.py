from PySide6.QtWidgets import QApplication, QMainWindow, QWidget, QVBoxLayout, QSizePolicy
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *
from umap import UMAP
from sklearn.neighbors import KDTree
import librosa
import numpy as np
import pickle
from sklearn.preprocessing import MinMaxScaler

def main():
    d = {
        # "path":"/Users/ted/Documents/_TEACHING/_materials/flucoma/FluCoMa-Pedagogical-Materials-repo/media/Nicol-LoopE-M.wav",
        "path": "/Users/sam/Library/Application Support/SuperCollider/sounds/analogSynthSounds/drums/manyHits.wav",
        "thresh":68.0,
        "min_slice_len":0.1,# in seconds
        "window_size":1024,
        "hop_size":512
    }
    y, sr = librosa.load(d["path"], sr=None)
    slice_points = MBufAnalysis.spectral_flux_onsets(d)
    print(slice_points.dtype)
    slice_points = np.insert(slice_points, 0, 0) # add start of file as first slice point
    slice_points = np.append(slice_points, len(y)) # add end of file as last slice point
    data = np.ndarray((len(slice_points)-1, 13)) # create array to hold slice features

    for i in range(len(slice_points)-1):
        start = int(slice_points[i])
        end = int(slice_points[i+1])
        print(f"Slice {i} / {len(slice_points)-1}: start={start}, end={end}, duration={(end-start)/sr:.2f} seconds")
        d["start_frame"] = start
        d["num_frames"] = end - start
        mfccs = MBufAnalysis.mfcc(d)
        data[i] = mfccs.mean()

    with open("mfcc.pkl", "wb") as f:
        pickle.dump(data, f)

    # data_norm = MinMaxScaler().fit_transform(data)

    print("data shape:", data.shape)

    data_umap = UMAP(n_components=2,learning_rate=0.1,min_dist=0.7,n_epochs=200).fit_transform(data)

    kdtree = KDTree(data_umap)

    ma = MMMAudio(128,graph_name="MPlotExample", package_name="examples")
    ma.start_audio()

    ma.send_string("load_sound", d["path"])

    prev = None

    def get_nearest(view, x, y, button, is_dragging, key, dblclick, step):
        nonlocal prev
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
    waveform_win = MWaveform(y, slice_points)
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

if __name__ == "__main__":
    main()