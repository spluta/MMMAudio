"""use this as a template for your own graphs"""

from mmm_src.MMMWorld import MMMWorld
from mmm_utils.Messengers import Messenger
from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from mmm_dsp.Distortion import *
from mmm_dsp.Osc import *

# there can only be one graph in an MMMAudio instance
# a graph can have as many synths as you want
struct TestSVF(Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var osc: LFSaw[1,2]
    var filts: List[SVF]
    var messenger: Messenger

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr
        self.osc = LFSaw[1,2](world_ptr)
        self.messenger = Messenger(world_ptr)
        self.filts = List[SVF](capacity=2)
        for i in range(2):
            self.filts[i] = SVF(world_ptr)

    fn next(mut self) -> SIMD[DType.float64, 2]:
        freq = self.messenger.get_val("freq", 440.0)
        sample = self.osc.next(freq) 
        outs = SIMD[DType.float64, 2](0.0,0.0)
        cutoff = self.messenger.get_val("cutoff", 1000.0)
        res = self.messenger.get_val("res", 1.0)
        outs[0] = self.filts[0].lpf(sample, cutoff, res)
        outs[1] = self.filts[1].hpf(sample, cutoff, res)
        return outs * 0.2