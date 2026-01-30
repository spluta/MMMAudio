"""RMS Unit Test"""

.Analysis import *
.Buffer_Module import *
.Play import *
from .MMMWorld_Module import *

comptime windowsize: Int = 1024
comptime hopsize: Int = 512

struct Analyzer(BufferedProcessable):
    var world: World
    var rms_values: List[Float64]

    fn __init__(out self, world: World):
        self.world = world
        self.rms_values = List[Float64]()

    fn next_window(mut self, mut buffer: List[Float64]):
        val = RMS.from_window(buffer)
        self.rms_values.append(val)
        return

fn main():
    world = MMMWorld()
    w = LegacyUnsafePointer(to=world)
    world.sample_rate = 44100.0

    buffer = Buffer.load("resources/Shiverer.wav")
    playBuf = Play(self.world)

    analyzer = BufferedInput[Analyzer,windowsize,hopsize](self.world, Analyzer(self.world))

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
