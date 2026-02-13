from PySide6.QtWidgets import QApplication
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parent.parent))
from mmm_python import *
from umap import UMAP
from sklearn.neighbors import KDTree
import librosa
import numpy as np
from sklearn.preprocessing import MinMaxScaler

d = {
    "path":"/Users/ted/Documents/_TEACHING/_materials/flucoma/FluCoMa-Pedagogical-Materials-repo/media/Nicol-LoopE-M.wav",
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
data = np.ndarray((len(slice_points)-1, 2)) # create array to hold slice features

for i in range(len(slice_points)-1):
    start = int(slice_points[i])
    end = int(slice_points[i+1])
    print(f"Slice {i}: start={start}, end={end}, duration={(end-start)/sr:.2f} seconds")
    d["start_frame"] = start
    d["num_frames"] = end - start
    sc = MBufAnalysis.spectral_centroid(d)
    rms = MBufAnalysis.rms(d)
    data[i, 0] = sc.mean()
    data[i, 1] = rms.mean()

data_norm = MinMaxScaler().fit_transform(data)

kdtree = KDTree(data_norm)

def get_nearest(view, x, y, button, is_dragging, key, dblclick, step):
    if step is None:
        dist, idx = kdtree.query([[x, y]], k=1)
        view.highlight_index(int(idx[0][0]))
        print(f"x: {x:.2f}, y: {y:.2f}")
        print(f"Nearest idx: {idx[0][0]}, dist: {dist[0][0]:.4f}")

app = QApplication([])
win = MPlot(data_norm, mouse_callback=get_nearest)
win.resize(700, 500)
win.show()
app.exec()