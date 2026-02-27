# run this from directly inside the "validation" directory, not from project root

import librosa
import os
import csv
import matplotlib.pyplot as plt
import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("--show-plots", action="store_true", help="Display plots interactively")
args = parser.parse_args()
show_plots = args.show_plots

os.makedirs("testing_mmm_audio/validation/validation_results", exist_ok=True)
os.makedirs("testing_mmm_audio/validation/mojo_results", exist_ok=True)
os.makedirs("testing_mmm_audio/validation/flucoma_sc_results", exist_ok=True)

flucoma_csv_path = "./testing_mmm_audio/validation/flucoma_sc_results/mel_bands_flucoma.csv"
if not os.path.exists(flucoma_csv_path):
    os.system("sclang ./testing_mmm_audio/validation/MelBands_Validation.scd")

os.system("mojo run -I . ./testing_mmm_audio/validation/MelBands_Validation.mojo")

with open(flucoma_csv_path, "r") as f:
    reader = csv.reader(f)
    flucoma_results = []
    for row in reader:
        flucoma_results.append([float(value) for value in row])
        
with open("./testing_mmm_audio/validation/mojo_results/mel_bands_mojo.csv", "r") as f:
    reader = csv.reader(f)
    mojo_results = []
    for row in reader:
        mojo_results.append([float(value) for value in row])

mojo_results = mojo_results[2:] # remove first two frames to "align" with others
mojo_results = np.array(mojo_results).T  # transpose to match librosa output shape
flucoma_results = np.array(flucoma_results).T  # transpose to match librosa output shape
    
y, sr = librosa.load("./resources/Shiverer.wav", sr=None)
librosa_results = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=10, n_fft=1024, hop_length=512, fmin=20.0, fmax=20000.0, center=False)

# Align arrays to the same size
min_frames = min(librosa_results.shape[1], flucoma_results.shape[1], mojo_results.shape[1])
librosa_aligned = librosa_results[:, :min_frames]
flucoma_aligned = flucoma_results[:, :min_frames]
mojo_aligned = mojo_results[:, :min_frames]

def compare_mel_bands(arr1, arr2, name1, name2):
    """Compare two mel band spectrograms and return mean and std of differences."""
    diff = arr1 - arr2
    mean_diff = np.mean(np.abs(diff))
    std_diff = np.std(diff)
    return mean_diff, std_diff

# Compute statistics
mojo_vs_librosa_mean, mojo_vs_librosa_std = compare_mel_bands(mojo_aligned, librosa_aligned, "MMMAudio", "Librosa")
mojo_vs_flucoma_mean, mojo_vs_flucoma_std = compare_mel_bands(mojo_aligned, flucoma_aligned, "MMMAudio", "FluCoMa")
librosa_vs_flucoma_mean, librosa_vs_flucoma_std = compare_mel_bands(librosa_aligned, flucoma_aligned, "Librosa", "FluCoMa")

print("N Librosa Frames: ", librosa_aligned.shape[1])
print("N FluCoMa Frames: ", flucoma_aligned.shape[1])
print("N Mojo Frames: ", mojo_aligned.shape[1])

# Print statistics
print("\n=== Mel Bands Comparison Statistics ===\n")
print(f"MMMAudio vs Librosa: Mean Difference = {mojo_vs_librosa_mean:.4f}, Std Dev = {mojo_vs_librosa_std:.4f}")
print(f"MMMAudio vs FluCoMa: Mean Difference = {mojo_vs_flucoma_mean:.4f}, Std Dev = {mojo_vs_flucoma_std:.4f}")
print(f"Librosa vs FluCoMa: Mean Difference = {librosa_vs_flucoma_mean:.4f}, Std Dev = {librosa_vs_flucoma_std:.4f}")

# Print as markdown table
print("\n=== Copy-Pasteable Markdown Table ===\n")
print("| Comparison          | Mean Difference | Std Dev of Differences |")
print("| ------------------- | --------------- | ---------------------- |")
print(f"| MMMAudio vs Librosa | {mojo_vs_librosa_mean:.4f}      | {mojo_vs_librosa_std:.4f}            |")
print(f"| MMMAudio vs FluCoMa | {mojo_vs_flucoma_mean:.4f}      | {mojo_vs_flucoma_std:.4f}            |")
print(f"| Librosa vs FluCoMa  | {librosa_vs_flucoma_mean:.4f}      | {librosa_vs_flucoma_std:.4f}            |")
print()

fig, ax = plt.subplots(nrows=3, ncols=1, sharex=True)
librosa.display.specshow(librosa.power_to_db(librosa_results, ref=np.max), sr=sr, hop_length=512, x_axis='time', y_axis='mel', ax=ax[0])
librosa.display.specshow(librosa.power_to_db(flucoma_results, ref=np.max), sr=sr, hop_length=512, x_axis='time', y_axis='mel', ax=ax[1])
librosa.display.specshow(librosa.power_to_db(mojo_results, ref=np.max), sr=sr, hop_length=512, x_axis='time', y_axis='mel', ax=ax[2])
ax[0].set(title='Librosa')
ax[1].set(title='FluCoMa')
ax[2].set(title='MMMAudio')
ax[0].label_outer()
plt.savefig("./testing_mmm_audio/validation/validation_results/mel_bands_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()
