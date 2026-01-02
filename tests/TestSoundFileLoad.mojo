from mmm_dsp.Buffer_Module import Buffer
from mmm_src.MMMWorld_Module import MMMWorld
from pathlib import Path

def main():

    buffer = Buffer.load("resources/Shiverer.wav")
    print("Loaded Buffer:")
    print("Sample Rate:", buffer.sample_rate)
    print("Number of Channels:", buffer.num_chans)
    print("Number of Frames:", buffer.num_frames)