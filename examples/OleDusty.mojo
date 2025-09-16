from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Osc import Dust
from mmm_utils.functions import *
from mmm_dsp.Filters import *

# THE SYNTH

struct Dusty(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var dust: Dust[2] 

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.dust = Dust[2](world_ptr)

    fn __repr__(self) -> String:
        return String("OleDusty")

    fn next(mut self, freq: Float64) -> SIMD[DType.float64, 2]:

        out = self.dust.next(freq)

        # uncomment below for use the phase of the Dust oscillator instead of the impulse
        # out = self.dust.get_phase()

        return out

# THE GRAPH

struct OleDusty(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var dusty: Dusty
    var reson: Reson[2]
    var freq: Float64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.dusty = Dusty(world_ptr)
        self.reson = Reson[2](world_ptr)
        self.freq = 20.0

    fn __repr__(self) -> String:
        return String("OleDusty")

    fn next(mut self) -> SIMD[DType.float64, 2]:

        freq = linexp(self.world_ptr[0].mouse_y, 0.0, 1.0, 100.0, 2000.0)

        out = self.dusty.next(linlin(self.world_ptr[0].mouse_x, 0.0, 1.0, 5.0, 200.0))

        # there is really no difference between ugens, synths, graphs
        # thus there is no reason you can't process the output of a synth directly in the graph
        # the reson filter uses SIMD to run 2 filters in parallel, each processing a channel of the dusty synth
        out = self.reson.hpf(out, freq, 10.0, 1.0)  # apply a bandpass filter to the output of the Dusty synth

        return out