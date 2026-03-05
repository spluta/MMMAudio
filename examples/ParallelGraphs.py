
"""
MMMAudio can run multiple graphs in parallel, each in its own process. This example shows how to create multiple MMMAudio instances, each with its own graph, and send messages to them independently.
"""

from mmm_python import *
import time

m_s = []

for i in range(4):
    m_s.append(MMMAudio(128, graph_name="ParallelGraphs", package_name="examples"))
    m_s[-1].start_process()
    m_s[-1].start_audio()
    m_s[-1].send_float("pan", linlin(i, 0, 3, -1, 1)) # pan each graph to a different position in the stereo field
    time.sleep(0.1)

# set the frequency to a random value
from random import random

picker = Pxrand([0,1,2,3])
def set_random_freq():
    m_s[picker.next()].send_float("freq", random() * 500 + 100) # set the frequency to a random value

set_random_freq()