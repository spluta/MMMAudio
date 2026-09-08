from mmm_python.MMMAudio import *
from mmm_python.functions import *
from mmm_python.Patterns import *
import asyncio
from asyncio import sleep
from mmm_python.OSCServer import *
from mmm_python.Scheduler import *
from mmm_python.GUI import *
from mmm_python.hid_devices import *
from mmm_python.BufAnalysis import *
from mmm_python.constants import *

import os, sys

# only for linux. load the alsa plugin dir for supriya_midi to work properly. 
if sys.platform == "linux" and "ALSA_PLUGIN_DIR" not in os.environ:
    for _alsa_dir in (
        "/usr/lib/x86_64-linux-gnu/alsa-lib",
        "/usr/lib/aarch64-linux-gnu/alsa-lib",
        "/usr/lib64/alsa-lib",
        "/usr/lib/alsa-lib",
    ):
        if os.path.isdir(_alsa_dir):
            os.environ["ALSA_PLUGIN_DIR"] = _alsa_dir
            break
        del _alsa_dir