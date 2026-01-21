"""YIN Unit Test

This script is intended to be run *from* the Python script that also does the
librosa analysis.

It outputs a CSV file with frequency and confidence results from analyzing
a WAV file using the YIN algorithm. The results can be compared to other implementations
such as librosa in Python.
"""

.Analysis import *
.Buffer_Module import *
.Play import *
from .MMMWorld_Module import *

comptime minfreq: Float64 = 100.0
comptime maxfreq: Float64 = 5000.0
comptime windowsize: Int = 1024
comptime hopsize: Int = 512

struct Analyzer(BufferedProcessable):
    var world: LegacyUnsafePointer[MMMWorld]
    var yin: YIN[windowsize, minfreq, maxfreq]
    var freqs: List[Float64]
    var confs: List[Float64]

    fn __init__(out self, world: LegacyUnsafePointer[MMMWorld]):
        self.world = world
        self.yin = YIN[windowsize, minfreq, maxfreq](self.world)
        self.freqs = List[Float64]()
        self.confs = List[Float64]()

    fn next_window(mut self, mut buffer: List[Float64]):
        self.yin.next_window(buffer)
        self.freqs.append(self.yin.pitch)
        self.confs.append(self.yin.confidence)
        return

fn main():
    w = MMMWorld()
    world = LegacyUnsafePointer(to=w)

    buffer = Buffer.load("resources/Shiverer.wav")
    world[].sample_rate = buffer.sample_rate
    playBuf = Play(world)

    analyzer = BufferedInput[Analyzer,windowsize,hopsize](world, Analyzer(world))

    for _ in range(buffer.num_frames):
        sample = playBuf.next(buffer, 0, 1)
        analyzer.next(sample)
    
    pth = "validation/outputs/yin_mojo_results.csv"
    try:
        with open(pth, "w") as f:
            f.write("windowsize,",windowsize,"\n")
            f.write("hopsize,",hopsize,"\n")
            f.write("minfreq,",minfreq,"\n")
            f.write("maxfreq,",maxfreq,"\n")
            f.write("Frequency,Confidence\n")
            for i in range(len(analyzer.process.freqs)):
                f.write(String(analyzer.process.freqs[i]) + "," + String(analyzer.process.confs[i]) + "\n")
        print("Wrote results to ", pth)
    except err:
        print("Error writing to file: ", err)
