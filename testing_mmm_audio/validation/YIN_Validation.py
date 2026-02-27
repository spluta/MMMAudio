"""YIN Unit Test

This script tests the YIN pitch detection implementation in the mmm_dsp library
by comparing its output against the librosa library's YIN implementation.

This script needs to be run from the root MMMAudio directory.

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

os.system("mojo run -I . testing_mmm_audio/validation/YIN_Validation.mojo")
print("mojo analysis complete")

with open("testing_mmm_audio/validation/mojo_results/yin_mojo_results.csv", "r") as f:
    lines = f.readlines()
    windowsize = int(lines[0].strip().split(",")[1])
    hopsize = int(lines[1].strip().split(",")[1])
    minfreq = float(lines[2].strip().split(",")[1])
    maxfreq = float(lines[3].strip().split(",")[1])
    
    mojo_analysis = []
    # skip line 4, its a header
    # skip line 5, to account for 1 frame lag
    for line in lines[6:]:
        freq, conf = line.strip().split(",")
        mojo_analysis.append((float(freq), float(conf)))

y, sr = librosa.load("resources/Shiverer.wav", sr=None)

pitch = librosa.yin(y, fmin=minfreq, fmax=maxfreq, sr=sr, frame_length=windowsize, hop_length=hopsize)

def get_semitone_diffs(list1, list2):
    shorter = min(len(list1), len(list2))
    arr1 = np.array(list1[:shorter])
    arr2 = np.array(list2[:shorter])
    
    # Replace 0s with epsilon to avoid div by zero
    epsilon = 1e-6
    arr1[arr1 < epsilon] = epsilon
    arr2[arr2 < epsilon] = epsilon
    
    # Semitones: 12 * log2(f1 / f2)
    diff_st = np.abs(12 * np.log2(arr1 / arr2))
    return diff_st

def compare_analyses_pitch(list1, list2):
    shorter = min(len(list1), len(list2))
    arr1 = np.array(list1[:shorter])
    arr2 = np.array(list2[:shorter])
    
    diff_hz = arr1 - arr2
    mean_hz = np.mean(np.abs(diff_hz))
    std_hz = np.std(diff_hz)
    
    # Replace 0s with epsilon to avoid div by zero for semitones
    epsilon = 1e-6
    arr1_safe = arr1.copy()
    arr2_safe = arr2.copy()
    arr1_safe[arr1_safe < epsilon] = epsilon
    arr2_safe[arr2_safe < epsilon] = epsilon
    
    # Semitones: 12 * log2(f1 / f2)
    diff_st = 12 * np.log2(arr1_safe / arr2_safe)
    mean_st = np.mean(np.abs(diff_st))
    std_st = np.std(diff_st)
    
    return mean_hz, std_hz, mean_st, std_st

def compare_analyses_confidence(list1, list2):
    shorter = min(len(list1), len(list2))
    arr1 = np.array(list1[:shorter])
    arr2 = np.array(list2[:shorter])
    
    diff = arr1 - arr2
    mean_diff = np.mean(np.abs(diff))
    std_diff = np.std(diff)
    
    return mean_diff, std_diff

try:
    flucoma_csv_path = "testing_mmm_audio/validation/flucoma_sc_results/yin_flucoma_results.csv"
    if not os.path.exists(flucoma_csv_path):
        os.system("sclang testing_mmm_audio/validation/YIN_Validation.scd")
except Exception as e:
    print("Error running SuperCollider script (make sure `sclang` can be called from the Terminal):", e)

fig, (ax_freq, ax_conf) = plt.subplots(2, 1, figsize=(12, 10), sharex=True)

limit = 600

# Frequency Plot
ax_freq.set_ylabel("Frequency (Hz)")
ax_freq.set_title("YIN Pitch Detection Comparison")

mojo_freqs = [f[0] for f in mojo_analysis]
# MMMAudio
l1 = ax_freq.plot(mojo_freqs[:limit], label="MMMAudio YIN", alpha=0.7)
color1 = l1[0].get_color()

# Librosa
l2 = ax_freq.plot(pitch[:limit], label="librosa YIN", alpha=0.7)

# Confidence Plot
ax_conf.set_ylabel("Confidence")
ax_conf.set_xlabel("Frame")

# MMMAudio Confidence
l3 = ax_conf.plot([f[1] for f in mojo_analysis][:limit], label="MMMAudio YIN Confidence", color=color1, alpha=0.7)

try:
    with open(flucoma_csv_path, "r") as f:
        lines = f.readlines()
        sclang_analysis = []
        # skip header
        for line in lines[1:]:
            parts = line.strip().split(",")
            if len(parts) >= 2:
                freq = float(parts[0])
                conf = float(parts[1])
                sclang_analysis.append((freq, conf))
            
    # FluCoMa Frequency
    sclang_freqs = [f[0] for f in sclang_analysis]
    l4 = ax_freq.plot(sclang_freqs[:limit], label="FluCoMa YIN", alpha=0.7)
    color4 = l4[0].get_color()
    
    # FluCoMa Confidence
    l5 = ax_conf.plot([f[1] for f in sclang_analysis][:limit], label="FluCoMa YIN Confidence", color=color4, alpha=0.7)
    
except Exception as e:
    print("Error reading FluCoMa results:", e)

ax_freq.legend()
ax_conf.legend()

mean_hz, std_hz, mean_st, std_st = compare_analyses_pitch(mojo_freqs, pitch)
print(f"MMMAudio vs Librosa YIN: Mean Dev = {mean_hz:.2f} Hz ({mean_st:.2f} semitones), Std Dev = {std_hz:.2f} Hz ({std_st:.2f} semitones)")

try:
    mean_hz, std_hz, mean_st, std_st = compare_analyses_pitch(mojo_freqs, sclang_freqs)
    print(f"MMMAudio vs FluCoMa YIN: Mean Dev = {mean_hz:.2f} Hz ({mean_st:.2f} semitones), Std Dev = {std_hz:.2f} Hz ({std_st:.2f} semitones)")
    
    mean_hz, std_hz, mean_st, std_st = compare_analyses_pitch(pitch, sclang_freqs)
    print(f"Librosa vs FluCoMa YIN: Mean Dev = {mean_hz:.2f} Hz ({mean_st:.2f} semitones), Std Dev = {std_hz:.2f} Hz ({std_st:.2f} semitones)")

    mojo_confs = [f[1] for f in mojo_analysis]
    sclang_confs = [f[1] for f in sclang_analysis]
    mean_conf, std_conf = compare_analyses_confidence(mojo_confs, sclang_confs)
    print(f"MMMAudio vs FluCoMa Confidence: Mean Dev = {mean_conf:.4f}, Std Dev = {std_conf:.4f}")
except Exception as e:
    print("Error comparing FluCoMa results:", e)

plt.tight_layout()
plt.savefig("testing_mmm_audio/validation/validation_results/yin_comparison.png")
if show_plots:
    plt.show()
else:
    plt.close()

# Histogram of deviations
plt.figure(figsize=(10, 6))
diffs_librosa = get_semitone_diffs(mojo_freqs, pitch)
max_val = np.max(diffs_librosa)
data_list = [diffs_librosa]
label_list = ['MMMAudio vs Librosa']

if 'sclang_freqs' in locals():
    diffs_flucoma = get_semitone_diffs(mojo_freqs, sclang_freqs)
    max_val = max(max_val, np.max(diffs_flucoma))
    data_list.append(diffs_flucoma)
    label_list.append('MMMAudio vs FluCoMa')

    diffs_flucoma_librosa = get_semitone_diffs(pitch, sclang_freqs)
    max_val = max(max_val, np.max(diffs_flucoma_librosa))
    data_list.append(diffs_flucoma_librosa)
    label_list.append('Librosa vs FluCoMa')

bins = np.arange(0, np.ceil(max_val) + 1, 1)
plt.hist(data_list, bins=bins, label=label_list, alpha=0.7)
plt.xlabel('Absolute Deviation (Semitones)')
plt.ylabel('Count of Frames')
plt.title('Histogram of Pitch Deviation (Semitones)')
plt.legend()
plt.xticks(bins)
plt.savefig("testing_mmm_audio/validation/validation_results/yin_deviation_histogram.png")
if show_plots:
    plt.show()
else:
    plt.close()