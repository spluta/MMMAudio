# Test the RK4 ODE solver with a simple harmonic oscillator.
# Should produce a clean sine wave tone.

from mmm_python.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestODEOsc", package_name="examples.tests")
mmm_audio.start_audio()

# Change frequency
mmm_audio.send_float("frequency", 220.0)  # A3
mmm_audio.send_float("frequency", 440.0)  # A4
mmm_audio.send_float("frequency", 880.0)  # A5

# Stop audio when done
mmm_audio.stop_audio()