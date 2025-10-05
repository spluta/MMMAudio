# you should not edit this file
# i don't want it to be in this directory, but it needs to be here due to a mojo compiler bug

from python import PythonObject
from python.bindings import PythonModuleBuilder

from os import abort
from memory import *

from mmm_src.MMMWorld import MMMWorld
# from mmm_src.MMMGraphs import MMMGraphs
from mmm_src.MMMGraph_solo import MMMGraph

from mmm_utils.functions import *
from mmm_src.MMMTraits import *
from utils import Variant

struct MMMAudioBridge(Representable, Movable):
    var world: MMMWorld  # Instance of MMMWorld
    var world_ptr: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var graph: MMMGraph

    var loc_in_buffer: UnsafePointer[SIMD[DType.float32, 1]]  # Placeholder for output buffer
    var loc_out_buffer: UnsafePointer[SIMD[DType.float64, 1]]  # Placeholder for output buffer

    var msg_dict: Dict[String, List[Float64]]

    @staticmethod
    fn py_init(out self: MMMAudioBridge, args: PythonObject, kwargs: PythonObject) raises:

        var sample_rate = Float64(args[0])
        var block_size: Int64 = Int64(args[1])

        var num_out_chans: Int64 = 2
        var num_in_chans: Int64 = 2

        # right now if you try to read args[3], shit gets really weird

        self = Self(sample_rate, block_size, num_in_chans, num_out_chans, [0])  # Initialize with sample rate, block size, and number of channels

    fn __init__(out self, sample_rate: Float64 = 44100.0, block_size: Int64 = 512, num_in_chans: Int64 = 12, num_out_chans: Int64 = 12, graphs: List[Int64] = List[Int64](0)):
        """Initialize the audio engine with sample rate, block size, and number of channels."""

        print("MMMAudioBridge initialized with sample rate:", sample_rate, "block size:", block_size)

        # it is way more efficient to use an UnsafePointer to write to the output buffer directly
        self.loc_in_buffer = UnsafePointer[SIMD[DType.float32, 1]]() 
        self.loc_out_buffer = UnsafePointer[SIMD[DType.float64, 1]]()  
        self.world = MMMWorld(sample_rate, block_size, num_in_chans, num_out_chans)  # Initialize MMMWorld with sample rate and block size
        self.world_ptr = UnsafePointer(to=self.world)  # Pointer to the MMMWorld instance

        self.graph = MMMGraph(self.world_ptr)

        self.msg_dict = Dict[String, List[Float64]]()

        print("AudioEngine initialized with sample rate:", self.world_ptr[0].sample_rate)

    @staticmethod
    fn set_channel_count(py_self: UnsafePointer[Self], args: PythonObject) raises -> PythonObject:
        var num_in_chans = Int64(args[0])
        var num_out_chans = Int64(args[1])
        print("set_channel_count:", num_in_chans, num_out_chans)
        py_self[0].world_ptr[0].set_channel_count(num_in_chans, num_out_chans)
        py_self[0].graph.set_channel_count(num_in_chans, num_out_chans)

        return PythonObject(None)

    fn __repr__(self) -> String:
        return String("MMMAudioBridge(sample_rate: " + String(self.world_ptr[0].sample_rate) + ", block_size: " + String(self.world_ptr[0].block_size) + ", num_in_chans: " + String(self.world_ptr[0].num_in_chans) + ", num_out_chans: " + String(self.world_ptr[0].num_out_chans) + ")")


    @staticmethod
    fn set_screen_dims(py_self: UnsafePointer[Self], dims: PythonObject) raises -> PythonObject:

        py_self[0].world_ptr[0].screen_dims = [Float64(dims[0]), Float64(dims[1])]  # Set the screen size in the MMMWorld instance

        return PythonObject(None) 

    @staticmethod
    fn send_raw_hid(py_self: UnsafePointer[Self], info: PythonObject) raises -> PythonObject:
        key = String(info[0])
        data = Int16(info[1])

        print(data)

        # py_self[0].world_ptr[0].send_raw_hid(key, data)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn send_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        var list = List[Float64]()

        var key = String(key_vals[0])
        for i in range(1,len(key_vals)):  
            list.append(Float64(key_vals[i]))  # Convert each value to Float64 and append to the list

        py_self[0].world_ptr[0].send_msg(key, list)
        
        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn send_text_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        var list = List[String]()

        var key = String(key_vals[0])
        for i in range(1,len(key_vals)):     
            list.append(String(key_vals[i]))  # Convert each value to String and append to the list

        py_self[0].world_ptr[0].send_text_msg(key, list)
        
        return PythonObject(None)  # Return a PythonObject wrapping None

    # @staticmethod
    # fn send_midi(py_self: UnsafePointer[Self], msg: PythonObject) raises -> PythonObject:

    #     py_self[0].world_ptr[0].send_midi(msg)

    #     return PythonObject(None)  # Return a PythonObject wrapping None
    
    @staticmethod
    fn send_midi(py_self: UnsafePointer[Self], msg: PythonObject) raises -> PythonObject:

        py_self[0].world_ptr[0].send_midi(msg)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn next(py_self: UnsafePointer[Self], in_buffer: PythonObject, out_buffer: PythonObject) raises -> PythonObject:

        py_self[0].loc_in_buffer = in_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float32]()

        py_self[0].loc_out_buffer = out_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()
        # zero the output buffer
        for j in range(py_self[0].world_ptr[0].num_out_chans):
            for i in range(py_self[0].world_ptr[0].block_size):
                py_self[0].loc_out_buffer[i * py_self[0].world_ptr[0].num_out_chans + j] = 0.0 

        py_self[0].graph.next(py_self[0].loc_in_buffer, py_self[0].loc_out_buffer, py_self[0].msg_dict)  

        return PythonObject(None)  # Return a PythonObject wrapping the float value

# this is needed to make the module importable in Python - so simple!
@export
fn PyInit_MMMAudioBridge() -> PythonObject:
    try:
        var m = PythonModuleBuilder("MMMAudioBridge")

        _ = (
            m.add_type[MMMAudioBridge]("MMMAudioBridge").def_py_init[MMMAudioBridge.py_init]()
            .def_method[MMMAudioBridge.next]("next")
            .def_method[MMMAudioBridge.set_screen_dims]("set_screen_dims")
            # .def_method[MMMAudioBridge.set_active_graphs]("set_active_graphs")
            .def_method[MMMAudioBridge.send_msg]("send_msg")
            .def_method[MMMAudioBridge.send_text_msg]("send_text_msg")
            .def_method[MMMAudioBridge.send_raw_hid]("send_raw_hid")
            .def_method[MMMAudioBridge.send_midi]("send_midi")
            .def_method[MMMAudioBridge.set_channel_count]("set_channel_count")
        )

        return m.finalize()
    except e:
        return abort[PythonObject](String("error creating Python Mojo module:", e))


