"""Spectral Centroid Unit Test

This script tests the Spectral Centroid implementation in the mmm_dsp library
by comparing its output against the librosa library's implementation.
"""

import librosa
import os
import matplotlib.pyplot as plt
import numpy as np

os.system("mojo run validation/SpectralCentroid_Validation.mojo")
print("mojo analysis complete")

with open("validation/outputs/spectral_centroid_mojo_results.csv", "r") as f:
    lines = f.readlines()
    windowsize = int(lines[0].strip().split(",")[1])
    hopsize = int(lines[1].strip().split(",")[1])
    
    mojo_centroids = []
    # skip line 2 (header)
    # skip line 3, to account for 1 frame lag
    for line in lines[4:]:
        val = float(line.strip())
        mojo_centroids.append(val)

y, sr = librosa.load("resources/Shiverer.wav", sr=None)

# Librosa Spectral Centroid
# center=False to match Mojo
librosa_centroids = librosa.feature.spectral_centroid(y=y, sr=sr, n_fft=windowsize, hop_length=hopsize, center=False)[0]

try:
    os.system("sclang validation/SpectralCentroid_Validation.scd")
    scrun = True
except Exception as e:
    print("Error running SuperCollider script:", e)

plt.figure(figsize=(12, 6))
plt.plot(mojo_centroids, label="MMMAudio Spectral Centroid", alpha=0.7)
plt.plot(librosa_centroids, label="librosa Spectral Centroid", alpha=0.7)

try:
    with open("validation/outputs/spectral_centroid_flucoma_results.csv", "r") as f:
        lines = f.readlines()
        sclang_centroids = []
        for line in lines:
            val = float(line.strip())
            sclang_centroids.append(val)
            
    plt.plot(sclang_centroids, label="FluCoMa Spectral Centroid", alpha=0.7)
except Exception as e:
    print("Error reading FluCoMa results:", e)    

plt.legend()
plt.title("Spectral Centroid Comparison")
plt.savefig("validation/outputs/spectral_centroid_comparison.png")
plt.show()
