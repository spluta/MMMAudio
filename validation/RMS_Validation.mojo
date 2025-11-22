"""RMS Unit Test"""

from mmm_dsp.Analysis import *
from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_src.MMMWorld import MMMWorld

alias windowsize: Int = 1024
alias hopsize: Int = 512

struct Analyzer(BufferedProcessable):
    var world_ptr: UnsafePointer[MMMWorld]
    var rms_values: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.rms_values = List[Float64]()

    fn next_window(mut self, mut buffer: List[Float64]):
        # Use Units.amp to match librosa.feature.rms output
        val = RMS[unit=Units.amp].from_window(buffer)
        self.rms_values.append(val)
        return

fn main():
    world = MMMWorld()
    world_ptr = UnsafePointer(to=world)
    world.sample_rate = 44100.0

    buffer = Buffer("resources/Shiverer.wav")
    playBuf = PlayBuf(world_ptr)

    analyzer = BufferedInput[Analyzer,windowsize,hopsize](world_ptr, Analyzer(world_ptr))

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
