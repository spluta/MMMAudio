"""Spectral Skewness Unit Test

This script tests the Spectral Skewness implementation in the MMMAudio library
by comparing its output against FluCoMa.
"""

import argparse
import os
import matplotlib.pyplot as plt
import numpy as np
import sys

sys.path.append(os.getcwd())


def parse_args():
    parser = argparse.ArgumentParser(description="Validate spectral skewness output.")
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

os.system("mojo run validation/SpectralSkewness_Validation.mojo")
print("mojo analysis complete")

with open("validation/outputs/spectral_skewness_mojo_results.csv", "r") as f:
    lines = f.readlines()
    windowsize = int(lines[0].strip().split(",")[1])
    hopsize = int(lines[1].strip().split(",")[1])

    mojo_skewness = []
    # skip line 2 (header)
    # skip line 3, to account for 1 frame lag
    for line in lines[4:]:
        val = float(line.strip())
        mojo_skewness.append(val)

def compare_analyses(list1, list2):
    shorter = min(len(list1), len(list2))
    arr1 = np.array(list1[:shorter])
    arr2 = np.array(list2[:shorter])
    diff = arr1 - arr2
    return np.mean(np.abs(diff)), np.std(diff)

flucoma_results = load_flucoma_spectral_shape(windowsize, hopsize)
flucoma_skewness = flucoma_results["skewness"]

plt.figure(figsize=(12, 6))
plt.plot(mojo_skewness, label="MMMAudio Spectral Skewness", alpha=0.7)

if flucoma_skewness:
    plt.plot(flucoma_skewness, label="FluCoMa Spectral Skewness", alpha=0.7)

if flucoma_skewness:
    try:
        mean_dev_flucoma, std_dev_flucoma = compare_analyses(mojo_skewness, flucoma_skewness)
        print(f"MMMAudio vs FluCoMa Spectral Skewness: Mean Dev = {mean_dev_flucoma:.6f}, Std Dev = {std_dev_flucoma:.6f}")
    except Exception as e:
        print("Error comparing FluCoMa results:", e)

plt.legend()
plt.title("Spectral Skewness Comparison")
plt.savefig("validation/outputs/spectral_skewness_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()
