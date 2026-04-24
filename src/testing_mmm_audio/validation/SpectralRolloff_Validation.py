"""Spectral Rolloff Unit Test

This script tests the Spectral Rolloff implementation in the MMMAudio library
by comparing its output against the librosa library's implementation.
"""

import argparse
import librosa
import os
import matplotlib.pyplot as plt
import numpy as np
import sys

sys.path.append(os.getcwd())


def parse_args():
    parser = argparse.ArgumentParser(description="Validate spectral rolloff output.")
    parser.add_argument(
        "--show-plots",
        action="store_true",
        help="Display plots interactively (pauses execution).",
    )
    return parser.parse_args()


args = parse_args()
show_plots = args.show_plots

os.makedirs("./testing_mmm_audio/validation/flucoma_sc_results", exist_ok=True)

def load_flucoma_spectral_shape(windowsize, hopsize):
    output_path = "./testing_mmm_audio/validation/flucoma_sc_results/spectral_shape_flucoma_results.csv"
    settings_path = "./testing_mmm_audio/validation/flucoma_sc_results/spectral_shape_settings.csv"

    if not os.path.exists(output_path):
        try:
            with open(settings_path, "w") as f:
                f.write(f"windowsize,{windowsize}\n")
                f.write(f"hopsize,{hopsize}\n")
            os.system("sclang ./SpectralShape_Validation.scd")
        except Exception as e:
            print("Error running SuperCollider script (make sure `sclang` can be called from the Terminal):", e)

    results = {
        "centroid": [],
        "spread": [],
        "skewness": [],
        "kurtosis": [],
        "rolloff": [],
        "flatness": [],
        "crest": [],
    }
    try:
        with open(output_path, "r") as f:
            for line in f:
                parts = [p.strip() for p in line.strip().split(",")]
                if len(parts) < 7:
                    continue
                results["centroid"].append(float(parts[0]))
                results["spread"].append(float(parts[1]))
                results["skewness"].append(float(parts[2]))
                results["kurtosis"].append(float(parts[3]))
                results["rolloff"].append(float(parts[4]))
                results["flatness"].append(float(parts[5]))
                results["crest"].append(float(parts[6]))
    except Exception as e:
        print("Error reading FluCoMa results:", e)
    return results

os.system("mojo run -I . ./testing_mmm_audio/validation/SpectralRolloff_Validation.mojo")
print("mojo analysis complete")

with open("./testing_mmm_audio/validation/mojo_results/spectral_rolloff_mojo_results.csv", "r") as f:
    lines = f.readlines()
    windowsize = int(lines[0].strip().split(",")[1])
    hopsize = int(lines[1].strip().split(",")[1])

    mojo_rolloff = []
    # skip line 2 (header)
    # skip line 3, to account for 1 frame lag
    for line in lines[4:]:
        val = float(line.strip())
        mojo_rolloff.append(val)

y, sr = librosa.load("./resources/Shiverer.wav", sr=None)

# Librosa Spectral Rolloff
librosa_rolloff = librosa.feature.spectral_rolloff(
    y=y,
    sr=sr,
    n_fft=windowsize,
    hop_length=hopsize,
    win_length=windowsize,
    window="hann",
    roll_percent=0.95,
    center=False,
)[0]

def compare_analyses(list1, list2):
    shorter = min(len(list1), len(list2))
    arr1 = np.array(list1[:shorter])
    arr2 = np.array(list2[:shorter])
    diff = arr1 - arr2
    return np.mean(np.abs(diff)), np.std(diff)

flucoma_results = load_flucoma_spectral_shape(windowsize, hopsize)
flucoma_rolloff = flucoma_results["rolloff"]

plt.figure(figsize=(12, 6))
plt.plot(mojo_rolloff, label="MMMAudio Spectral Rolloff", alpha=0.7)
plt.plot(librosa_rolloff, label="librosa Spectral Rolloff", alpha=0.7)

if flucoma_rolloff:
    plt.plot(flucoma_rolloff, label="FluCoMa Spectral Rolloff", alpha=0.7)

mean_dev_librosa, std_dev_librosa = compare_analyses(mojo_rolloff, librosa_rolloff)
print(f"MMMAudio vs Librosa Spectral Rolloff: Mean Dev = {mean_dev_librosa:.4f}, Std Dev = {std_dev_librosa:.4f}")

if flucoma_rolloff:
    try:
        mean_dev_flucoma, std_dev_flucoma = compare_analyses(mojo_rolloff, flucoma_rolloff)
        print(f"MMMAudio vs FluCoMa Spectral Rolloff: Mean Dev = {mean_dev_flucoma:.4f}, Std Dev = {std_dev_flucoma:.4f}")

        mean_dev_lib_flu, std_dev_lib_flu = compare_analyses(librosa_rolloff, flucoma_rolloff)
        print(f"Librosa vs FluCoMa Spectral Rolloff: Mean Dev = {mean_dev_lib_flu:.4f}, Std Dev = {std_dev_lib_flu:.4f}")
    except Exception as e:
        print("Error comparing FluCoMa results:", e)

plt.legend()
plt.ylabel("Hz")
plt.title("Spectral Rolloff Comparison")
plt.savefig("testing_mmm_audio/validation/validation_results/spectral_rolloff_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()
