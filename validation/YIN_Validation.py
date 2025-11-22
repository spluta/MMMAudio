"""YIN Unit Test

This script tests the YIN pitch detection implementation in the mmm_dsp library
by comparing its output against the librosa library's YIN implementation.

This script needs to be run from the root MMMAudio directory.

"""

import librosa
import os
import matplotlib.pyplot as plt

os.system("mojo run validation/YIN_Validation.mojo")
print("mojo analysis complete")

with open("validation/outputs/yin_mojo_results.csv", "r") as f:
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

try:
    os.system("sclang validation/YIN_Validation.scd")
except Exception as e:
    print("Error running SuperCollider script:", e)

fig, (ax_freq, ax_conf) = plt.subplots(2, 1, figsize=(12, 10), sharex=True)

limit = 300

# Frequency Plot
ax_freq.set_ylabel("Frequency (Hz)")
ax_freq.set_title("YIN Pitch Detection Comparison")

# MMMAudio
l1 = ax_freq.plot([f[0] for f in mojo_analysis][:limit], label="MMMAudio YIN", alpha=0.7)
color1 = l1[0].get_color()

# Librosa
l2 = ax_freq.plot(pitch[:limit], label="librosa YIN", alpha=0.7)

# Confidence Plot
ax_conf.set_ylabel("Confidence")
ax_conf.set_xlabel("Frame")

# MMMAudio Confidence
l3 = ax_conf.plot([f[1] for f in mojo_analysis][:limit], label="MMMAudio YIN Confidence", color=color1, alpha=0.7)

try:
    with open("validation/outputs/yin_flucoma_results.csv", "r") as f:
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
    l4 = ax_freq.plot([f[0] for f in sclang_analysis][:limit], label="FluCoMa YIN", alpha=0.7)
    color4 = l4[0].get_color()
    
    # FluCoMa Confidence
    l5 = ax_conf.plot([f[1] for f in sclang_analysis][:limit], label="FluCoMa YIN Confidence", color=color4, alpha=0.7)
    
except Exception as e:
    print("Error reading FluCoMa results:", e)

ax_freq.legend()
ax_conf.legend()

plt.tight_layout()
plt.savefig("validation/outputs/yin_comparison.png")
plt.show()