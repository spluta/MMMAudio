"""RMS Unit Test

This script tests the RMS implementation in the mmm_dsp library
by comparing its output against the librosa library's RMS implementation.
"""

import librosa
import os
import matplotlib.pyplot as plt
import numpy as np

os.system("mojo run validation/RMS_Validation.mojo")
print("mojo analysis complete")

with open("validation/outputs/rms_mojo_results.csv", "r") as f:
    lines = f.readlines()
    windowsize = int(lines[0].strip().split(",")[1])
    hopsize = int(lines[1].strip().split(",")[1])
    
    mojo_rms = []
    # skip line 2 (header)
    # skip line 3, to account for 1 frame lag
    for line in lines[4:]:
        val = float(line.strip())
        mojo_rms.append(val)

y, sr = librosa.load("resources/Shiverer.wav", sr=None)

# Librosa RMS
# center=False to match Mojo's BufferedInput behavior better
librosa_rms = librosa.feature.rms(y=y, frame_length=windowsize, hop_length=hopsize, center=False)[0]

try:
    os.system("sclang validation/RMS_Validation.scd")
    scrun = True
except Exception as e:
    print("Error running SuperCollider script:", e)

plt.figure(figsize=(12, 6))
plt.plot(mojo_rms, label="MMMAudio RMS", alpha=0.7)
plt.plot(librosa_rms, label="librosa RMS", alpha=0.7)

try:
    with open("validation/outputs/rms_flucoma_results.csv", "r") as f:
        lines = f.readlines()
        sclang_rms = []
        for line in lines:
            val = float(line.strip())
            sclang_rms.append(val)
            
    plt.plot(sclang_rms, label="FluCoMa RMS", alpha=0.7)
except Exception as e:
    print("Error reading FluCoMa results:", e)

plt.legend()
plt.ylabel("Amplitude")
plt.title("RMS Comparison")
plt.savefig("validation/outputs/rms_comparison.png")
plt.show()
