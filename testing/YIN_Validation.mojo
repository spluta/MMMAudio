"""YIN Unit Test

This script is intended to be run *from* the Python script that also does the
librosa analysis.

It outputs a CSV file with frequency and confidence results from analyzing
a WAV file using the YIN algorithm. The results can be compared to other implementations
such as librosa in Python.
"""

from mmm_audio import *

comptime minfreq: Float64 = 100.0
comptime maxfreq: Float64 = 5000.0
comptime windowsize: Int = 1024
comptime hopsize: Int = 512

struct Analyzer(BufferedProcessable):
    var world: World
    var yin: YIN[windowsize, minfreq, maxfreq]
    var freqs: List[Float64]
    var confs: List[Float64]

    fn __init__(out self, world: World):
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
    w = alloc[MMMWorld](1)
    w.init_pointee_move(MMMWorld(44100.0))

    buffer = Buffer.load("resources/Shiverer.wav")
    w[].sample_rate = buffer.sample_rate
    playBuf = Play(w)

    analyzer = BufferedInput[Analyzer,windowsize,hopsize](w, Analyzer(w))

    for _ in range(buffer.num_frames):
        sample = playBuf.next(buffer)
        analyzer.next(sample)
    
    pth = "testing/mojo_results/yin_mojo_results.csv"
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
