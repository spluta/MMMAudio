"""MFCC Unit Test

This script tests the MFCC implementation in the MMMAudio library by comparing
its output against librosa and FluCoMa.
"""

import argparse
import csv
import librosa
import matplotlib.pyplot as plt
import numpy as np
import os
import sys

sys.path.append(os.getcwd())


def parse_args():
	parser = argparse.ArgumentParser(description="Validate MFCC output.")
	parser.add_argument(
		"--show-plots",
		action="store_true",
		help="Display plots interactively (pauses execution).",
	)
	return parser.parse_args()


args = parse_args()
show_plots = args.show_plots

os.makedirs("validation/outputs", exist_ok=True)

os.system("mojo run validation/MFCC_Validation.mojo")
print("mojo analysis complete")

flucoma_csv_path = "validation/outputs/mfcc_flucoma_results.csv"
if not os.path.exists(flucoma_csv_path):
	try:
		os.system("sclang validation/MFCC_Validation.scd")
	except Exception as e:
		print("Error running SuperCollider script (make sure `sclang` can be called from the Terminal):", e)
else:
	print("FluCoMa CSV already exists, skipping .scd execution")

with open("validation/outputs/mfcc_mojo_results.csv", "r") as f:
	lines = f.readlines()

	windowsize = int(lines[0].strip().split(",")[1])
	hopsize = int(lines[1].strip().split(",")[1])
	num_coeffs = int(lines[2].strip().split(",")[1])
	num_bands = int(lines[3].strip().split(",")[1])
	min_freq = float(lines[4].strip().split(",")[1])
	max_freq = float(lines[5].strip().split(",")[1])

	mojo_results = []
	for line in lines[7:]:
		row = [float(value) for value in line.strip().split(",") if value != ""]
		if row:
			mojo_results.append(row)

with open("validation/outputs/mfcc_flucoma_results.csv", "r") as f:
	reader = csv.reader(f)
	flucoma_results = []
	for row in reader:
		flucoma_results.append([float(value) for value in row])

if len(mojo_results) > 2:
	mojo_results = mojo_results[2:]  # remove first two frames to align with others

mojo_results = np.array(mojo_results).T
flucoma_results = np.array(flucoma_results).T

y, sr = librosa.load("resources/Shiverer.wav", sr=None)
librosa_results = librosa.feature.mfcc(
	y=y,
	sr=sr,
	n_mfcc=num_coeffs,
	n_fft=windowsize,
	hop_length=hopsize,
	n_mels=num_bands,
	fmin=min_freq,
	fmax=max_freq,
	center=False,
	dct_type=2,
	norm="ortho",
)

# Align arrays to the same size
min_frames = min(librosa_results.shape[1], flucoma_results.shape[1], mojo_results.shape[1])
librosa_aligned = librosa_results[:, :min_frames]
flucoma_aligned = flucoma_results[:, :min_frames]
mojo_aligned = mojo_results[:, :min_frames]

def compare_mfcc(arr1, arr2):
	"""Compare two MFCC arrays and return mean and std of differences."""
	diff = arr1 - arr2
	mean_diff = np.mean(np.abs(diff))
	std_diff = np.std(diff)
	return mean_diff, std_diff

mojo_vs_librosa_mean, mojo_vs_librosa_std = compare_mfcc(mojo_aligned, librosa_aligned)
mojo_vs_flucoma_mean, mojo_vs_flucoma_std = compare_mfcc(mojo_aligned, flucoma_aligned)
librosa_vs_flucoma_mean, librosa_vs_flucoma_std = compare_mfcc(librosa_aligned, flucoma_aligned)

print("N Librosa Frames: ", librosa_aligned.shape[1])
print("N FluCoMa Frames: ", flucoma_aligned.shape[1])
print("N Mojo Frames: ", mojo_aligned.shape[1])

print("\n=== MFCC Comparison Statistics ===\n")
print(f"MMMAudio vs Librosa: Mean Difference = {mojo_vs_librosa_mean:.6f}, Std Dev = {mojo_vs_librosa_std:.6f}")
print(f"MMMAudio vs FluCoMa: Mean Difference = {mojo_vs_flucoma_mean:.6f}, Std Dev = {mojo_vs_flucoma_std:.6f}")
print(f"Librosa vs FluCoMa: Mean Difference = {librosa_vs_flucoma_mean:.6f}, Std Dev = {librosa_vs_flucoma_std:.6f}")

print("\n=== Copy-Pasteable Markdown Table ===\n")
print("| Comparison          | Mean Difference | Std Dev of Differences |")
print("| ------------------- | --------------- | ---------------------- |")
print(f"| MMMAudio vs Librosa | {mojo_vs_librosa_mean:.6f}      | {mojo_vs_librosa_std:.6f}            |")
print(f"| MMMAudio vs FluCoMa | {mojo_vs_flucoma_mean:.6f}      | {mojo_vs_flucoma_std:.6f}            |")
print(f"| Librosa vs FluCoMa  | {librosa_vs_flucoma_mean:.6f}      | {librosa_vs_flucoma_std:.6f}            |")
print()

fig, ax = plt.subplots(nrows=3, ncols=1, sharex=True)
ax[0].imshow(librosa_results, aspect="auto", origin="lower")
ax[1].imshow(flucoma_results, aspect="auto", origin="lower")
ax[2].imshow(mojo_results, aspect="auto", origin="lower")
ax[0].set(title="Librosa", ylabel="MFCC")
ax[1].set(title="FluCoMa", ylabel="MFCC")
ax[2].set(title="MMMAudio", xlabel="Frame", ylabel="MFCC")
plt.tight_layout()
plt.savefig("validation/outputs/mfcc_comparison.png")
if show_plots:
	plt.show()
else:
	plt.close()
