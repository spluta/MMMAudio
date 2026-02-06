
from mmm_audio import *
from random import random

# User defined struct that just operates on two lists
# and therefore is useful for operating on mags and phases.
# Things like this can basically be used like the PV_
# pattern in SuperCollider, stringing together a bunch of
# operations on the mags and phases.
struct BinScramble(Copyable,Movable):
    var swaps: List[Tuple[Int64,Int64]]
    var nbins: Int64
    var nscrambles: Int64
    var scramble_range: Int64

    fn __init__(out self, nbins: Int64, nscrambles: Int64):
        self.nbins = nbins
        self.nscrambles = nscrambles
        self.swaps = List[Tuple[Int64,Int64]]()
        self.scramble_range = 10
        self.new_swaps()

    fn new_swaps(mut self) -> None:
        self.swaps.clear()
        for _ in range(self.nscrambles):
            i = random.random_si64(0, self.nbins - 1)
            minj = max(i - self.scramble_range,0)
            maxj = min(i + self.scramble_range, self.nbins - 1)
            j = random.random_si64(minj, maxj)
            self.swaps.append((i,j))

    fn next(mut self, mut magnitudes: List[Float64], mut phases: List[Float64]) -> None:
        for (i,j) in self.swaps:
            temp_mag = magnitudes[i]
            magnitudes[i] = magnitudes[j]
            magnitudes[j] = temp_mag
            temp_phase = phases[i]
            phases[i] = phases[j]
            phases[j] = temp_phase

# User defined struct that implements FFTProcessable
struct ScrambleAndLowPass[window_size: Int = 1024](FFTProcessable):
    var world: World
    var m: Messenger
    var bin: Int64
    var bin_scramble: BinScramble

    fn __init__(out self, world: World):
        self.world = world
        self.bin = (self.window_size // 2) + 1
        self.m = Messenger(self.world)
        self.bin_scramble = BinScramble(nbins=(self.window_size // 2) + 1, nscrambles=20)

    fn get_messages(mut self) -> None:
        self.m.update(self.bin,"lpbin")
        self.m.update(self.bin_scramble.nscrambles,"nscrambles")
        self.m.update(self.bin_scramble.scramble_range,"scramble_range")
        if self.m.notify_trig("rescramble"):
            self.bin_scramble.new_swaps()

    fn next_frame(mut self, mut magnitudes: List[Float64], mut phases: List[Float64]) -> None:
        self.bin_scramble.next(magnitudes,phases)
        for i in range(self.bin,(self.window_size // 2) + 1):
            magnitudes[i] *= 0.0

# User's Main Synth
struct TestFFTProcess(Movable, Copyable):
    var world: World
    var buffer: Buffer
    var playBuf: Play
    var fftlowpass: FFTProcess[ScrambleAndLowPass[1024],1024,512,WindowType.hann,WindowType.hann]
    var m: Messenger
    var ps: List[Print]
    var which: Float64

    fn __init__(out self, world: World):
        self.world = world
        self.buffer = Buffer.load("resources/Shiverer.wav")
        self.playBuf = Play(self.world) 
        self.fftlowpass = FFTProcess[ScrambleAndLowPass[1024],1024,512,WindowType.hann,WindowType.hann](self.world,process=ScrambleAndLowPass[1024](self.world))
        self.m = Messenger(self.world)
        self.ps = List[Print](length=2,fill=Print(self.world))
        self.which = 0

    fn next(mut self) -> SIMD[DType.float64,2]:
        i = self.playBuf.next(self.buffer, 1.0, True)  # Read samples from the buffer
        o = self.fftlowpass.next(i)
        return SIMD[DType.float64,2](o,o)

