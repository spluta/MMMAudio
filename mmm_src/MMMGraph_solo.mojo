from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import *

from python import PythonObject

from mmm_utils.functions import *
from examples.Default_Graph import Default_Graph

struct MMMGraph(Representable, Movable):
    var world_ptr: UnsafePointer[MMMWorld]
    var graph: Default_Graph
    var output: List[Float64]  # Output list for audio samples

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], graphs: List[Int64] = List[Int64](0)):
        self.world_ptr = world_ptr  # Pointer to the MMMWorld instance

        self.output = List[Float64]()
        for _ in range(self.world_ptr[0].num_chans):
            self.output.append(0.0)  # Initialize output list with zeros

        self.graph = Default_Graph(self.world_ptr)

    fn __repr__(self) -> String:
        return String("MMMGraph")

    fn get_audio_samples(mut self: MMMGraph, loc_wire_buffer: UnsafePointer[Float64]):

        for i in range(self.world_ptr[0].block_size):
            
            if i == 0:
                self.world_ptr[0].grab_messages = 1  # Set grab_messages to True for the first sample

            zero(self.output)
            self.output = self.graph.next()

            if i == 0:
                self.world_ptr[0].clear_msgs()

            # Fill the wire buffer with the sample data
            for j in range(self.world_ptr[0].num_chans):
                if j < self.output.__len__(): 
                    loc_wire_buffer[i * 2 + j] += self.output[j]  # Fill the wire buffer with the sample data

    fn next(mut self: MMMGraph, loc_wire_buffer: UnsafePointer[Float64], mut msg_dict: Dict[String, List[Float64]]) raises:
        self.get_audio_samples(loc_wire_buffer)  # Get audio samples for each active graph"
        