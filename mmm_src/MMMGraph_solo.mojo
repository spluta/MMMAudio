from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import *

from python import PythonObject

from mmm_utils.functions import *
from examples.Midi_Sequencer import Midi_Sequencer

struct MMMGraph(Representable, Movable):
    var world_ptr: UnsafePointer[MMMWorld]
    var graph: Midi_Sequencer
    var num_out_chans: Int64

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], graphs: List[Int64] = List[Int64](0)):
        self.world_ptr = world_ptr  # Pointer to the MMMWorld instance

        self.num_out_chans = self.world_ptr[0].num_out_chans

        self.graph = Midi_Sequencer(self.world_ptr)

    fn set_channel_count(mut self, num_in_chans: Int64, num_out_chans: Int64):
        self.num_out_chans = num_out_chans

    fn __repr__(self) -> String:
        return String("MMMGraph")

    fn get_audio_samples(mut self: MMMGraph, loc_in_buffer: UnsafePointer[Float32], loc_out_buffer: UnsafePointer[Float64]):

        for i in range(self.world_ptr[0].block_size):
            self.world_ptr[0].block_state = i  # Update the block state

            if i == 0:
                self.world_ptr[0].transfer_pooled_messages()

            # fill the sound_in list with the current sample from all inputs
            for j in range(self.world_ptr[0].num_in_chans):
                self.world_ptr[0].sound_in[j] = Float64(loc_in_buffer[i * self.world_ptr[0].num_in_chans + j]) 

            samples = self.graph.next()  # Get the next audio samples from the graph

            self.world_ptr[0].untrigger_all_messengers()

            # Fill the wire buffer with the sample data
            for j in range(min(self.num_out_chans, samples.__len__())):
                loc_out_buffer[i * self.num_out_chans + j] = samples[Int(j)]

    fn next(mut self: MMMGraph, loc_in_buffer: UnsafePointer[Float32], loc_out_buffer: UnsafePointer[Float64], mut msg_dict: Dict[String, List[Float64]]) raises:
        self.get_audio_samples(loc_in_buffer, loc_out_buffer)
        