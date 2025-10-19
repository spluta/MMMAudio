from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

from mmm_dsp.Buffer import *
from mmm_dsp.PlayBuf import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_utils.functions import linexp
from random import random_float64

# THE SYNTH

struct GrainSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: Buffer

    var num_chans: Int64
    
    var tgrains: TGrains[10]
    var impulse: Impulse  
    var start_frame: Float64
     
    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr  

        # buffer uses numpy to load a buffer into an N channel array
        self.buffer = Buffer("resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        self.tgrains = TGrains[10](self.world_ptr)  
        self.impulse = Impulse(self.world_ptr)


        self.start_frame = 0.0 

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        imp_freq = linlin(self.world_ptr[0].mouse_y, 0.0, 1.0, 1.0, 20.0)
        var impulse = self.impulse.next_bool(imp_freq, True)  # Get the next impulse sample

        start_frame = linlin(self.world_ptr[0].mouse_x, 0.0, 1.0, 0.0, self.buffer.get_num_frames())

        # use the first channel of the buffer
        var grains = self.tgrains.next(self.buffer, 0, impulse, 1, start_frame, 0.4, random_float64(-1.0, 1.0), 1.0)

        # if you want to use both channels of the buffer, uncomment this and comment the line above
        # with the 2 channel version, there will be 2 channels of output (in stereo), but no panning
        # var grains = self.tgrains.next[N=2](self.buffer, 0, impulse, 1, start_frame, 0.4, random_float64(-1.0, 1.0), 0.4) 

        return grains


    fn __repr__(self) -> String:
        return String("GrainSynth")

# THE GRAPH

struct Grains(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var grain_synth: GrainSynth  # Instance of the GrainSynth


    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.grain_synth = GrainSynth(world_ptr)  # Initialize the GrainSynth with the world instance

    fn __repr__(self) -> String:
        return String("TGrains")

    @always_inline
    fn next(mut self: Grains) -> SIMD[DType.float64, 2]:
        sample = self.grain_synth.next()

        return sample  # Return the combined output sample