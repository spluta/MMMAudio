"""YIN Unit Test

This script tests the YIN pitch detection implementation in the mmm_dsp library
by comparing its output against the librosa library's YIN implementation.

This script needs to be run from the root MMMAudio directory.

"""

import librosa
import os
import matplotlib.pyplot as plt

os.system("mojo run test_suite/YIN_Unit_Test.mojo")
print("mojo analysis complete")

with open("test_suite/outputs/yin_results.csv", "r") as f:
    lines = f.readlines()
    windowsize = int(lines[0].strip().split(",")[1])
    hopsize = int(lines[1].strip().split(",")[1])
    minfreq = float(lines[2].strip().split(",")[1])
    maxfreq = float(lines[3].strip().split(",")[1])
    
    mojo_analysis = []
    # skip line 4, its a header
    for line in lines[5:]:
        freq, conf = line.strip().split(",")
        mojo_analysis.append((float(freq), float(conf)))



y, sr = librosa.load("resources/Shiverer.wav", sr=None)

pitch = librosa.yin(y, fmin=minfreq, fmax=maxfreq, sr=sr, frame_length=windowsize, hop_length=hopsize)

plt.figure(figsize=(12, 6))

# plot confidence form 0-1 on secondary axis
ax1 = plt.gca()
ax2 = ax1.twinx()

ax1.set_xlabel("Frame")
ax1.set_ylabel("Frequency (Hz)")
l1 = ax1.plot([f[0] for f in mojo_analysis], label="MMMAudio YIN", alpha=0.7)
l2 = ax1.plot(pitch, label="librosa YIN", alpha=0.7)

ax2.set_ylabel("Confidence", color="green")
ax2.tick_params(axis='y', labelcolor="green")
l3 = ax2.plot([f[1] for f in mojo_analysis], label="MMMAudio YIN Confidence", color="green", alpha=0.7)

lns = l1 + l2 + l3
labs = [str(l.get_label()) for l in lns]
ax1.legend(lns, labs, loc=0)

plt.title("YIN Pitch Detection Comparison")
plt.savefig("test_suite/outputs/yin_comparison.png")
plt.show()