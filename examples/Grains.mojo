from mmm_src.MMMWorld import *
from mmm_utils.functions import *


from mmm_dsp.SoundFile import *
from mmm_dsp.Play import *
from mmm_dsp.Osc import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_utils.functions import linexp
from random import random_float64

# THE SYNTH

struct GrainSynth(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var sf: SoundFile
    
    var tgrains: TGrains[10]
    var impulse: Impulse  
     
    def __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w  

        # buffer uses numpy to load a buffer into an N channel array
        self.sf = SoundFile.load(w,"resources/Shiverer.wav")

        self.tgrains = TGrains[10](self.w)  
        self.impulse = Impulse(self.w)

    @always_inline
    fn next(mut self) -> SIMD[DType.float64, 2]:

        x = self.w[].mouse_x
        y = self.w[].mouse_y

        imp_freq = linlin(y, 0.0, 1.0, 1.0, 20.0)
        var impulse = self.impulse.next_bool(imp_freq, True)  # Get the next impulse sample

        start_frame = Int64(linlin(x, 0.0, 1.0, 0.0, self.sf.num_frames_f64 - 1.0))

        # use the first channel of the buffer
        var grains = self.tgrains.next(self.sf.data[0], 0, impulse, 1, start_frame, 0.4, random_float64(-1.0, 1.0), 1.0)

        # if you want to use both channels of the buffer, uncomment this and comment the line above
        # with the 2 channel version, there will be 2 channels of output (in stereo), but no panning
        # var grains = self.tgrains.next[N=2](self.sf.data, 0, impulse, 1, start_frame, 0.4, random_float64(-1.0, 1.0), 0.4) 

        return grains

    fn __repr__(self) -> String:
        return String("GrainSynth")

# THE GRAPH

struct Grains(Representable, Movable, Copyable):
    var w: UnsafePointer[MMMWorld]
    var grain_synth: GrainSynth  # Instance of the GrainSynth


    def __init__(out self, w: UnsafePointer[MMMWorld]):
        self.w = w

        self.grain_synth = GrainSynth(w)  # Initialize the GrainSynth with the world instance

    fn __repr__(self) -> String:
        return String("TGrains")

    @always_inline
    fn next(mut self: Grains) -> SIMD[DType.float64, 2]:
        sample = self.grain_synth.next()

        return sample  # Return the combined output sample