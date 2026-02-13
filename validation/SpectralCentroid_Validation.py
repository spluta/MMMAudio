"""Spectral Centroid Unit Test

This script tests the Spectral Centroid implementation in the mmm_dsp library
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
    parser = argparse.ArgumentParser(description="Validate spectral centroid output.")
    parser.add_argument(
        "--show-plots",
        action="store_true",
        help="Display plots interactively (pauses execution).",
    )
    return parser.parse_args()


args = parse_args()
show_plots = args.show_plots

os.makedirs("validation/outputs", exist_ok=True)

def load_flucoma_spectral_shape(windowsize, hopsize):
    output_path = "validation/outputs/spectral_shape_flucoma_results.csv"
    settings_path = "validation/outputs/spectral_shape_settings.csv"

    if not os.path.exists(output_path):
        try:
            with open(settings_path, "w") as f:
                f.write(f"windowsize,{windowsize}\n")
                f.write(f"hopsize,{hopsize}\n")
            os.system("sclang validation/SpectralShape_Validation.scd")
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

def compare_analyses_pitch(list1, list2):
    shorter = min(len(list1), len(list2))
    arr1 = np.array(list1[:shorter])
    arr2 = np.array(list2[:shorter])
    
    # Filter out zero or very low frequencies to avoid log errors or huge jumps
    mask = (arr1 > 10) & (arr2 > 10)
    arr1 = arr1[mask]
    arr2 = arr2[mask]
    
    diff_hz = arr1 - arr2
    mean_hz = np.mean(np.abs(diff_hz))
    std_hz = np.std(diff_hz)
    
    # Semitones: 12 * log2(f1 / f2)
    diff_st = 12 * np.log2(arr1 / arr2)
    mean_st = np.mean(np.abs(diff_st))
    std_st = np.std(diff_st)
    
    return mean_hz, std_hz, mean_st, std_st

flucoma_results = load_flucoma_spectral_shape(windowsize, hopsize)
flucoma_centroids = flucoma_results["centroid"]

plt.figure(figsize=(12, 6))
plt.plot(mojo_centroids, label="MMMAudio Spectral Centroid", alpha=0.7)
plt.plot(librosa_centroids, label="librosa Spectral Centroid", alpha=0.7)

if flucoma_centroids:
    plt.plot(flucoma_centroids, label="FluCoMa Spectral Centroid", alpha=0.7)

plt.legend()
plt.title("Spectral Centroid Comparison")

mean_hz, std_hz, mean_st, std_st = compare_analyses_pitch(mojo_centroids, librosa_centroids)
print(f"MMMAudio vs Librosa Spectral Centroid: Mean Dev = {mean_hz:.2f} Hz ({mean_st:.2f} semitones), Std Dev = {std_hz:.2f} Hz ({std_st:.2f} semitones)")

if flucoma_centroids:
    try:
        mean_hz, std_hz, mean_st, std_st = compare_analyses_pitch(mojo_centroids, flucoma_centroids)
        print(f"MMMAudio vs FluCoMa Spectral Centroid: Mean Dev = {mean_hz:.2f} Hz ({mean_st:.2f} semitones), Std Dev = {std_hz:.2f} Hz ({std_st:.2f} semitones)")

        mean_hz, std_hz, mean_st, std_st = compare_analyses_pitch(librosa_centroids, flucoma_centroids)
        print(f"Librosa vs FluCoMa Spectral Centroid: Mean Dev = {mean_hz:.2f} Hz ({mean_st:.2f} semitones), Std Dev = {std_hz:.2f} Hz ({std_st:.2f} semitones)")
    except Exception as e:
        print("Error comparing FluCoMa results:", e)

plt.savefig("validation/outputs/spectral_centroid_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()
