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

d = {
    # "path":"/Users/ted/Documents/_TEACHING/_materials/flucoma/FluCoMa-Pedagogical-Materials-repo/media/Nicol-LoopE-M.wav",
    "path": "/Users/ted/Desktop/all_flucoma.wav",
    "thresh":68.0,
    "min_slice_len":0.1,# in seconds
    "window_size":1024,
    "hop_size":512,
    "num_coeffs": 14
}
y, sr = librosa.load(d["path"], sr=None)
slice_points = MBufAnalysis.spectral_flux_onsets(d)
print(slice_points.dtype)
slice_points = np.insert(slice_points, 0, 0) # add start of file as first slice point
slice_points = np.append(slice_points, len(y)) # add end of file as last slice point
data = np.ndarray((len(slice_points)-1, d["num_coeffs"]-1)) # create array to hold slice features

print("n slice points:", len(slice_points))

for i in range(len(slice_points)-1):
    start = int(slice_points[i])
    end = int(slice_points[i+1])
    print(f"Slice {i} / {len(slice_points)-1}: start={start}, end={end}, duration={(end-start)/sr:.2f} seconds")
    d["start_frame"] = start
    d["num_frames"] = end - start
    mfccs = MBufAnalysis.mfcc(d)
    mfccs = mfccs[:, 1:] # drop first coefficient
    data[i] = mfccs.mean(axis=0)
    print(f"MFCCs for slice {i}: {data[i]}")

print("data shape:", data.shape)

d["data"] = data
d["slice_points"] = slice_points

np.savetxt("mfcc.csv", data, delimiter=",")

with open("analysis.pkl", "wb") as f:
    pickle.dump(d, f)