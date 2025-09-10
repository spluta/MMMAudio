from mmm_src.MMMWorld import MMMWorld
from mmm_utils.functions import *
from mmm_src.MMMTraits import *

# THE SYNTH - is imported from TorchSynth.mojo in this directory
from .TorchSynth import TorchSynth

# THE GRAPH

struct Torch_MLP(Representable, Movable, Graphable, Copyable):
    var world_ptr: UnsafePointer[MMMWorld]

    var output: List[Float64]  # Output buffer for audio samples

    var torch_synth: TorchSynth  # Instance of the TorchSynth

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld]):
        self.world_ptr = world_ptr

        self.torch_synth = TorchSynth(world_ptr)  # Initialize the TorchSynth with the world instance

        self.output = List[Float64](0.0, 0.0)  # Initialize output list

    fn __repr__(self) -> String:
        return String("Torch_MLP")

    fn next(mut self: Torch_MLP) -> List[Float64]:
        sample = self.torch_synth.next()

        return sample^  # Return the combined output sample