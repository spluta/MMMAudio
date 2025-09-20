from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

# THE SYNTH - is imported from TorchSynth.mojo in this directory
from .TorchSynth import TorchSynth

# THE GRAPH

struct Torch_Mlp(Representable, Movable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]
    var torch_synth: TorchSynth  # Instance of the TorchSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.torch_synth = TorchSynth(world_ptr)  # Initialize the TorchSynth with the world instance

    fn __repr__(self) -> String:
        return String("Torch_Mlp")

    fn next(mut self: Torch_Mlp) -> SIMD[DType.float64, 2]:
        return self.torch_synth.next()