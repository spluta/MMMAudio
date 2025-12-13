"""RMS Unit Test"""

from mmm_dsp.Analysis import *
from mmm_dsp.SoundFile import *
from mmm_dsp.Play import *
from mmm_src.MMMWorld import *

alias windowsize: Int = 1024
alias hopsize: Int = 512

struct Analyzer(BufferedProcessable):
    var w: UnsafePointer[MMMWorld]
    var rms_values: List[Float64]

    fn __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w
        self.rms_values = List[Float64]()

    fn next_window(mut self, mut buffer: List[Float64]):
        val = RMS.from_window(buffer)
        self.rms_values.append(val)
        return

fn main():
    world = MMMWorld()
    w = UnsafePointer(to=world)
    world.sample_rate = 44100.0

    buffer = SoundFile.load("resources/Shiverer.wav")
    playBuf = Play(w)

    analyzer = BufferedInput[Analyzer,windowsize,hopsize](w, Analyzer(w))

    for _ in range(buffer.num_frames):
        sample = playBuf.next(buffer, 0, 1)
        analyzer.next(sample)
    
    pth = "validation/outputs/rms_mojo_results.csv"
    try:
        with open(pth, "w") as f:
            f.write("windowsize,",windowsize,"\n")
            f.write("hopsize,",hopsize,"\n")
            f.write("RMS\n")
            for i in range(len(analyzer.process.rms_values)):
                f.write(String(analyzer.process.rms_values[i]) + "\n")
        print("Wrote results to ", pth)
    except err:
        print("Error writing to file: ", err)
