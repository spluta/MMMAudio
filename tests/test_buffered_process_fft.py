import os
import sys
from pathlib import Path

# This example is able to run by pressing the "play" button in VSCode
# that executes the whole file.
# In order to do this, it needs to add the parent directory to the path
# (the next line here) so that it can find the mmm_src and mmm_utils packages.
# If you want to run it line by line in a REPL, skip this line!
sys.path.insert(0, str(Path(__file__).parent.parent))

# Set Mojo import path BEFORE importing any Mojo modules
os.environ['MOJO_IMPORT_PATH'] = '/Users/ted/dev/MMMAudio:/Users/ted/dev/MMMAudio/SciJo:/Users/ted/dev/MMMAudio/NuMojo'

from mmm_src.MMMAudio import MMMAudio

mmm_audio = MMMAudio(128, graph_name="TestBufferedProcessFFT", package_name="tests")
mmm_audio.start_audio() 

# listen to only the processed audio
mmm_audio.send_float("which",1.0)

# volume should go down
mmm_audio.send_float("vol",-12.0)

# unprocessed audio still at full volume
mmm_audio.send_float("which",0.0)

# bring volume back up
mmm_audio.send_float("vol",0.0)

# should hear a tiny delay fx when mixed?
mmm_audio.send_float("which",0.5)

mmm_audio.stop_audio()