"""RMS Unit Test

This script tests the RMS implementation in the mmm_dsp library
by comparing its output against the librosa library's RMS implementation.
"""

import librosa
import os
import matplotlib.pyplot as plt
import numpy as np
import sys
import argparse

sys.path.append(os.getcwd())

parser = argparse.ArgumentParser()
parser.add_argument("--show-plots", action="store_true", help="Display plots interactively")
args = parser.parse_args()
show_plots = args.show_plots

os.makedirs("testing_mmm_audio/validation/validation_results", exist_ok=True)
os.makedirs("testing_mmm_audio/validation/mojo_results", exist_ok=True)
os.makedirs("testing_mmm_audio/validation/flucoma_sc_results", exist_ok=True)

os.system("mojo run -I . testing_mmm_audio/validation/RMS_Validation.mojo")
print("mojo analysis complete")

with open("testing_mmm_audio/validation/mojo_results/rms_mojo_results.csv", "r") as f:
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

def compare_analyses(list1, list2):
    shorter = min(len(list1), len(list2))
    list1 = list1[:shorter]
    list2 = list2[:shorter]
    diff = np.array(list1) - np.array(list2)
    return np.mean(np.abs(diff)), np.std(diff)

try:
    flucoma_csv_path = "testing_mmm_audio/validation/flucoma_sc_results/rms_flucoma_results.csv"
    if not os.path.exists(flucoma_csv_path):
        os.system("sclang testing_mmm_audio/validation/RMS_Validation.scd")
except Exception as e:
    print("Error running SuperCollider script (make sure `sclang` can be called from the Terminal):", e)

plt.figure(figsize=(12, 6))
plt.plot(mojo_rms, label="MMMAudio RMS", alpha=0.7)
plt.plot(librosa_rms, label="librosa RMS", alpha=0.7)

try:
    with open(flucoma_csv_path, "r") as f:
        lines = f.readlines()
        sclang_rms = []
        for line in lines:
            val = float(line.strip())
            sclang_rms.append(val)

    plt.plot(sclang_rms, label="FluCoMa RMS", alpha=0.7)
except Exception as e:
    print("Error reading FluCoMa results:", e)

mean_dev_librosa, std_dev_librosa = compare_analyses(mojo_rms, librosa_rms)
print(f"MMMAudio vs Librosa RMS: Mean Deviation = {float(mean_dev_librosa)} dB, Std Dev = {float(std_dev_librosa)} dB")

try:
    mean_dev_flucoma, std_dev_flucoma = compare_analyses(mojo_rms, sclang_rms)
    print(f"MMMAudio vs FluCoMa RMS: Mean Deviation = {float(mean_dev_flucoma)} dB, Std Dev = {float(std_dev_flucoma)} dB")
    
    mean_dev_lib_flu, std_dev_lib_flu = compare_analyses(librosa_rms, sclang_rms)
    print(f"Librosa vs FluCoMa RMS: Mean Deviation = {float(mean_dev_lib_flu)} dB, Std Dev = {float(std_dev_lib_flu)} dB")
except Exception as e:
    print("Error comparing FluCoMa results:", e)

plt.legend()
plt.ylabel("Amplitude")
plt.title("RMS Comparison")
plt.savefig("testing_mmm_audio/validation/validation_results/rms_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()
