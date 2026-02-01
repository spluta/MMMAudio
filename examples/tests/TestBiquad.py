from mmm_python.MMMAudio import MMMAudio

# Test Biquad filter with white noise sweeps
# Left channel: LPF, Right channel: HPF
mmm_audio = MMMAudio(128, graph_name="TestBiquad", package_name="examples.tests")
mmm_audio.start_audio()

# Sweep cutoff frequency from low to high
print("Sweeping cutoff from 100Hz to 8000Hz...")
for cutoff in [100.0, 200.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0]:
    mmm_audio.send_float("cutoff", cutoff)
    print(f"  Cutoff: {cutoff}Hz - Listen: LPF (left), HPF (right)")
    input("  Press Enter to continue...")

# Test resonance
print("\nTesting resonance at 1000Hz...")
mmm_audio.send_float("cutoff", 1000.0)
for q in [0.7, 2.0, 5.0, 10.0]:
    mmm_audio.send_float("q", q)
    print(f"  Q: {q} - Should hear resonance peak")
    input("  Press Enter to continue...")

mmm_audio.stop_audio()