from mmm_dsp.SoundFile import SoundFile
from mmm_src.MMMWorld import MMMWorld
from pathlib import Path

def main():

    sf = SoundFile("resources/Shiverer.wav")
    print("Loaded SoundFile:")
    print("Sample Rate:", sf.sample_rate)
    print("Number of Channels:", sf.num_chans)
    print("Number of Frames:", sf.num_frames)