from mmm_src.MMMAudio import *
from random import random

from mmm_src.hid_devices import * 

# list_audio_devices()

mmm_audio = MMMAudio(128, graph_name="Torch_MLP", package_name="mine")

list_hid_devices()

mmm_audio.add_hid_device("Extreme 3D pro", 0x046d, 0xc215)

mmm_audio.joysticks[0].verbose = True

mmm_audio.start_audio()