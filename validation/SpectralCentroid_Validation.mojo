"""Spectral Centroid Unit Test"""

from mmm_dsp.Analysis import *
from mmm_dsp.Buffer import *
from mmm_dsp.Play import *
from mmm_dsp.FFT import *
from mmm_src.MMMWorld import *

alias windowsize: Int = 1024
alias hopsize: Int = 512

struct Analyzer(BufferedProcessable):
    var world: UnsafePointer[MMMWorld]
    var fft: RealFFT[windowsize]
    var centroids: List[Float64]
    var sample_rate: Float64

    fn __init__(out self, world: UnsafePointer[MMMWorld], sample_rate: Float64):
        self.world = world
        self.fft = RealFFT[windowsize]()
        self.centroids = List[Float64]()
        self.sample_rate = sample_rate

    fn next_window(mut self, mut buffer: List[Float64]):
        self.fft.fft(buffer)
        # Passing in the "self.sample_rate" here instead of using the w sample rate
        # because the w was causing issues. Somehow the pointer was getting losses or something.
        val = SpectralCentroid.from_mags(self.fft.mags, self.sample_rate)
        self.centroids.append(val)
        return

fn main():
    world = MMMWorld()
    world.sample_rate = 44100.0
    w = UnsafePointer(to=world)

    buffer = Buffer.load("resources/Shiverer.wav")
    playBuf = Play(self.world)
    analyzer = BufferedInput[Analyzer,windowsize,hopsize,WindowType.hann](w, Analyzer(w,world.sample_rate))

    for _ in range(buffer.num_frames):
        sample = playBuf.next(buffer, 0, 1)
        analyzer.next(sample)
    
    pth = "validation/outputs/spectral_centroid_mojo_results.csv"
    try:
        with open(pth, "w") as f:
            f.write("windowsize,",windowsize,"\n")
            f.write("hopsize,",hopsize,"\n")
            f.write("Centroid\n")
            for i in range(len(analyzer.process.centroids)):
                f.write(String(analyzer.process.centroids[i]) + "\n")
        print("Wrote results to ", pth)
    except err:
        print("Error writing to file: ", err)
