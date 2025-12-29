# from mmm_src.MMMWorld import *
# 

# from mmm_graphs.MMMGraph0 import MMMGraph0
# from mmm_graphs.MMMGraph1 import MMMGraph1
# from mmm_graphs.MMMGraph2 import MMMGraph2
# from mmm_graphs.MMMGraph3 import MMMGraph3
# from mmm_graphs.MMMGraph4 import MMMGraph4
# from mmm_graphs.MMMGraph5 import MMMGraph5
# from mmm_graphs.MMMGraph6 import MMMGraph6
# from mmm_graphs.MMMGraph7 import MMMGraph7
# from mmm_graphs.MMMGraph8 import MMMGraph8
# from mmm_graphs.MMMGraph9 import MMMGraph9

# from python import PythonObject

# from mmm_utils.functions import *
# from algorithm import parallelize

# struct MMMGraphs(Representable, Movable):
#     var world: UnsafePointer[MMMWorld]
#     var graphs: Tuple[MMMGraph0, MMMGraph1, MMMGraph2, MMMGraph3, MMMGraph4, MMMGraph5, MMMGraph6, MMMGraph7, MMMGraph8, MMMGraph9]
#     var active_graphs: List[Int64]
#     var output: List[Float64]  # Output list for audio samples

#     fn __init__(out self, world: UnsafePointer[MMMWorld], graphs: List[Int64] = List[Int64](0)):
#         self.world = world  # Pointer to the MMMWorld instance

#         self.output = List[Float64]()
#         for _ in range(self.world[].num_chans):
#             self.output.append(0.0)  # Initialize output list with zeros

#         self.active_graphs = graphs
        
#         self.graphs = Tuple[MMMGraph0, MMMGraph1, MMMGraph2, MMMGraph3, MMMGraph4, MMMGraph5, MMMGraph6, MMMGraph7, MMMGraph8, MMMGraph9](
#             MMMGraph0(self.world), 
#             MMMGraph1(self.world),
#             MMMGraph2(self.world),
#             MMMGraph3(self.world),
#             MMMGraph4(self.world),
#             MMMGraph5(self.world),
#             MMMGraph6(self.world),
#             MMMGraph7(self.world),
#             MMMGraph8(self.world),
#             MMMGraph9(self.world)
#         )
    
#     fn __repr__(self) -> String:
#         return String("MMMGraphs")

#     fn set_active_graphs(mut self: MMMGraphs, args: PythonObject) raises:
#         self.active_graphs = List[Int64]()

#         var num = min(len(args), 10)

#         for i in range(num):
#             self.active_graphs.append(Int64(args[i]))  # Convert each argument to Int64 and append to the list
#             print("Graph added:", self.active_graphs[-1])

#     fn get_audio_samples(mut self: MMMGraphs, index: Int64, loc_wire_buffer: UnsafePointer[Float64]):

#         for i in range(self.world[].block_size):
            
#             if i == 0:
#                 self.world[].block_state = 1  # Set block_state to True for the first sample
#                 # if self.world[].block_size == 1:
#                 #     # reset trigger messages to 0.0 after the messages have been sent
#                 #     # self.world[].reset_trigger_msgs()  # Reset trigger messages in
#                 #     # self.world[].block_state = -1
#                 #     self.world[].clear_msgs()
#             # if self.world[].block_size > 1:
#             #     if i == 1:
#             #         # reset trigger messages to 0.0 after the messages have been sent
#             #         # self.world[].reset_trigger_msgs()  # Reset trigger messages in
#             #         # self.world[].block_state = -1
#             #         self.world[].clear_msgs()
#             #         self.world[].block_state = 0
#             # if self.world[].block_size > 2:
#             #     if i == 2:
#             #         self.world[].block_state = 0

#             zero(self.output)
#             # Get the next sample from the AudioGraph
#             if index == 0:
#                 self.output = self.graphs[0].next()
#             if index == 1:
#                 self.output = self.graphs[1].next()
#             elif index == 2:
#                 self.output = self.graphs[2].next()
#             elif index == 3:
#                 self.output = self.graphs[3].next()
#             elif index == 4:
#                 self.output = self.graphs[4].next()
#             elif index == 5:
#                 self.output = self.graphs[5].next()
#             elif index == 6:
#                 self.output = self.graphs[6].next()
#             elif index == 7:
#                 self.output = self.graphs[7].next()
#             elif index == 8:
#                 self.output = self.graphs[8].next()
#             elif index == 9:
#                 self.output = self.graphs[9].next()
            
#             # i have no idea if messages can arrive between the top of this loop and here
#             # that would result in missed messages
#             if i == 0:
#                 self.world[].clear_msgs()

#             # Fill the wire buffer with the sample data
#             for j in range(self.world[].num_chans):
#                 if j < self.output.__len__(): 
#                     loc_wire_buffer[i * 2 + j] += self.output[j]  # Fill the wire buffer with the sample data

#     fn next(mut self: MMMGraphs, loc_wire_buffer: UnsafePointer[Float64], mut msg_dict: Dict[String, List[Float64]]) raises:
#         # this will eventually need to be parallelized
#         for i in self.active_graphs:
#             self.get_audio_samples(i, loc_wire_buffer)  # Get audio samples for each active graph