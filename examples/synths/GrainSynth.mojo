from mmm_dsp.Buffer import *
from mmm_dsp.Filters import VAMoogLadder
from mmm_utils.functions import linexp
from random import random_float64
from mmm_src.MMMWorld import MMMWorld
from mmm_dsp.PlayBuf import *

struct GrainSynth(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var buffer: InterleavedBuffer

    var num_chans: Int64
    
    var tgrains: TGrains
    var impulse: Impulse  
    var start_frame: Float64  
    var counter: Int64
    
    var moog: List[VAMoogLadder]
     

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr  

        # interleaved buffer uses numpy to load a buffer into an interleaved array
        self.buffer = InterleavedBuffer(self.world_ptr, "resources/Shiverer.wav")
        self.num_chans = self.buffer.num_chans  

        self.tgrains = TGrains(self.world_ptr, 20)  
        self.impulse = Impulse(self.world_ptr)  

        self.moog = List[VAMoogLadder]()
        for _ in range(self.num_chans):
            self.moog.append(VAMoogLadder(self.world_ptr)) 

        self.start_frame = 0.0 

        self.counter = 0

    fn next(mut self) -> List[Float64]:

        imp_freq = linlin(self.world_ptr[0].mouse_y, 0.0, 1.0, 5.0, 40.0)
        var impulse = self.impulse.next(imp_freq, 1.0)  # Get the next impulse sample

        start_frame = linlin(self.world_ptr[0].mouse_x, 0.0, 1.0, 0.0, self.buffer.get_num_frames())

        var grains = self.tgrains.next(self.buffer, impulse, 1, start_frame, 0.4, random_float64(-1.0, 1.0), 0.4)  # Get grains from TGrains
        # var mod_val = self.mod.next(osc_buffers, 0.1, 1)  # Get the modulation value from the Osc
        
        # for i in range(self.num_chans):
        #     sample[i] = self.moog[i].next(sample[i], linexp(mod_val, -1.0, 1.0, 500.0, 20000.0), 0.5)

        return grains

    fn __repr__(self) -> String:
        return String("GrainSynth")