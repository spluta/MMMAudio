from mmm_dsp.SoundFile import SoundFile
from mmm_src.MMMWorld import MMMWorld
from pathlib import Path

def main():
    w = MMMWorld()
    
    path = Path("resources/Shiverer.wav")
    
    if not path.exists():
        raise Error("TestSoundFileLoad: File does not exist at path: " + path.name())
    else:
        for _ in range(100):
            print("TestSoundFileLoad: File exists at path: " + path.name())

    sf = SoundFile.load(UnsafePointer(to=w), path.name())