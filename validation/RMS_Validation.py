"""RMS Unit Test

This script tests the RMS implementation in the mmm_dsp library
by comparing its output against the librosa library's RMS implementation.
"""

import argparse
import librosa
import os
import matplotlib.pyplot as plt
import numpy as np
import sys
# from .functions import ampdb

sys.path.append(os.getcwd())
from mmm_python import *

def parse_args():
    parser = argparse.ArgumentParser(description="Validate RMS output.")
    parser.add_argument(
        "--show-plots",
        action="store_true",
        help="Display plots interactively (pauses execution).",
    )
    return parser.parse_args()


args = parse_args()
show_plots = args.show_plots

os.makedirs("validation/outputs", exist_ok=True)

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

def compare_analyses(list1, list2):
    shorter = min(len(list1), len(list2))
    list1 = list1[:shorter]
    list2 = list2[:shorter]
    diff = np.array(list1) - np.array(list2)
    return np.mean(np.abs(diff)), np.std(diff)

flucoma_csv_path = "validation/outputs/rms_flucoma_results.csv"
if not os.path.exists(flucoma_csv_path):
	try:
		os.system("sclang validation/RMS_Validation.scd")
		scrun = True
	except Exception as e:
		print("Error running SuperCollider script (make sure `sclang` can be called from the Terminal):", e)
else:
	print("FluCoMa CSV already exists, skipping .scd execution")
	scrun = True

mojo_rms_db = [ampdb(float(val)) for val in mojo_rms]
librosa_rms_db = [ampdb(float(val)) for val in librosa_rms]

plt.figure(figsize=(12, 6))
plt.plot(mojo_rms_db, label="MMMAudio RMS (dB)", alpha=0.7)
plt.plot(librosa_rms_db, label="librosa RMS (dB)", alpha=0.7)

try:
    with open("validation/outputs/rms_flucoma_results.csv", "r") as f:
        lines = f.readlines()
        sclang_rms = []
        for line in lines:
            val = float(line.strip())
            sclang_rms.append(val)

    sclang_rms_db = [ampdb(float(val)) for val in sclang_rms]
    plt.plot(sclang_rms_db, label="FluCoMa RMS (dB)", alpha=0.7)
except Exception as e:
    print("Error reading FluCoMa results:", e)

mean_dev_librosa, std_dev_librosa = compare_analyses(mojo_rms, librosa_rms)
print(f"MMMAudio vs Librosa RMS: Mean Deviation = {ampdb(float(mean_dev_librosa)):.2f} dB, Std Dev = {ampdb(float(std_dev_librosa)):.2f} dB")

try:
    mean_dev_flucoma, std_dev_flucoma = compare_analyses(mojo_rms, sclang_rms)
    print(f"MMMAudio vs FluCoMa RMS: Mean Deviation = {ampdb(float(mean_dev_flucoma)):.2f} dB, Std Dev = {ampdb(float(std_dev_flucoma)):.2f} dB")
    
    mean_dev_lib_flu, std_dev_lib_flu = compare_analyses(librosa_rms, sclang_rms)
    print(f"Librosa vs FluCoMa RMS: Mean Deviation = {ampdb(float(mean_dev_lib_flu)):.2f} dB, Std Dev = {ampdb(float(std_dev_lib_flu)):.2f} dB")
except Exception as e:
    print("Error comparing FluCoMa results:", e)

plt.legend()
plt.ylabel("dB")
plt.title("RMS Comparison")
plt.savefig("validation/outputs/rms_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()
