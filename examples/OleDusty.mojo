from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.Osc import Dust
from mmm_utils.functions import *
from mmm_dsp.Filters import *

# THE SYNTH

struct Dusty(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var dust: Dust
    var dust2: Dust
    var out: List[Float64]  

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.dust = Dust(world_ptr)
        self.dust2 = Dust(world_ptr)

        self.out = List[Float64](2, 0.0)  # Initialize with two zeros for stereo output

    fn __repr__(self) -> String:
        return String("OleDusty")

    fn next(mut self, freq: Float64) -> List[Float64]:

        out = [self.dust.next(freq), self.dust2.next(freq)]

        # uncomment below for use the phase of the Dust oscillator instead of the impulse
        # out = [self.dust.get_phase(), self.dust2.get_phase()]

        return out^

# THE GRAPH

struct OleDusty(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]  
    var dusty: Dusty
    var reson: Reson
    var reson2: Reson
    var freq: Float64
    var out: List[Float64]

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.dusty = Dusty(world_ptr)
        self.reson = Reson(world_ptr)
        self.reson2 = Reson(world_ptr)
        self.freq = 20.0

        self.out = List[Float64](2, 0.0)  # Initialize with two zeros for stereo output

    fn __repr__(self) -> String:
        return String("OleDusty")

    fn next(mut self) -> List[Float64]:
        # zero(self.out) # zero the output

        freq = linexp(self.world_ptr[0].mouse_y, 0.0, 1.0, 100.0, 2000.0)

        out = self.dusty.next(linlin(self.world_ptr[0].mouse_x, 0.0, 1.0, 5.0, 200.0))
        out[0] = self.reson.bpf(out[0], freq, 10.0, 1.0)  
        out[1] = self.reson2.bpf(out[1], freq, 10.0, 1.0) 

        return out^