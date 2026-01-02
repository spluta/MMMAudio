
from mmm_audio import *

def main():

    buffer = Buffer.load("resources/Shiverer.wav")
    print("Loaded Buffer:")
    print("Sample Rate:", buffer.sample_rate)
    print("Number of Channels:", buffer.num_chans)
    print("Number of Frames:", buffer.num_frames)