# you should not edit this file
# i don't want it to be in this directory, but it needs to be here due to a mojo compiler bug

from python import PythonObject
from python.bindings import PythonModuleBuilder

from os import abort
from memory import *

from mmm_src.MMMWorld import *

from mmm_utils.functions import *


from examples.Grains import Grains

struct MMMAudioBridge(Representable, Movable):
    var w: UnsafePointer[MMMWorld]  # Pointer to the MMMWorld instance

    var graph: Grains  # The audio graph instance

    var loc_in_buffer: UnsafePointer[SIMD[DType.float32, 1]]  # Placeholder for output buffer
    var loc_out_buffer: UnsafePointer[SIMD[DType.float64, 1]]  # Placeholder for output buffer

    @staticmethod
    fn py_init(out self: MMMAudioBridge, args: PythonObject, kwargs: PythonObject) raises:

        var sample_rate = Float64(args[0])
        var block_size: Int64 = Int64(args[1])

        var num_out_chans: Int64 = 2
        var num_in_chans: Int64 = 2

        # right now if you try to read args[3], shit gets really weird

        self = Self(sample_rate, block_size, num_in_chans, num_out_chans, [0])  # Initialize with sample rate, block size, and number of channels

    def __init__(out self, sample_rate: Float64 = 44100.0, block_size: Int64 = 512, num_in_chans: Int64 = 12, num_out_chans: Int64 = 12, graphs: List[Int64] = List[Int64](0)):
        """Initialize the audio engine with sample rate, block size, and number of channels."""

        # it is way more efficient to use an UnsafePointer to write to the output buffer directly
        self.loc_in_buffer = UnsafePointer[SIMD[DType.float32, 1]]() 
        self.loc_out_buffer = UnsafePointer[SIMD[DType.float64, 1]]()
        
        # Allocate MMMWorld on heap so it never moves
        self.w = UnsafePointer[MMMWorld].alloc(1)
        __get_address_as_uninit_lvalue(self.w.address) = MMMWorld(sample_rate, block_size, num_in_chans, num_out_chans)

        self.graph = Grains(self.w)

    @staticmethod
    fn set_channel_count(py_self: UnsafePointer[Self], args: PythonObject) raises -> PythonObject:
        var num_in_chans = Int64(args[0])
        var num_out_chans = Int64(args[1])
        print("set_channel_count:", num_in_chans, num_out_chans)
        py_self[0].w[].set_channel_count(num_in_chans, num_out_chans)
    
        return None # PythonObject(None)

    fn __repr__(self) -> String:
        return String("MMMAudioBridge(sample_rate: " + String(self.w[].sample_rate) + ", block_size: " + String(self.w[].block_size) + ", num_in_chans: " + String(self.w[].num_in_chans) + ", num_out_chans: " + String(self.w[].num_out_chans) + ")")

    @staticmethod
    fn set_screen_dims(py_self: UnsafePointer[Self], dims: PythonObject) raises -> PythonObject:

        py_self[0].w[].screen_dims = [Float64(dims[0]), Float64(dims[1])]  # Set the screen size in the MMMWorld instance

        return PythonObject(None) 

    @staticmethod
    fn send_raw_hid(py_self: UnsafePointer[Self], info: PythonObject) raises -> PythonObject:
        key = String(info[0])
        data = Int16(info[1])

        print(data)

        # py_self[0].w[].send_raw_hid(key, data)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_mouse_pos(py_self: UnsafePointer[Self], pos: PythonObject) raises -> PythonObject:

        py_self[0].w[].mouse_x = Float64(pos[0])
        py_self[0].w[].mouse_y = Float64(pos[1])

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_bool_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        py_self[0].w[].messengerManager.update_bool_msg(String(key_vals[0]), Bool(key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_bools_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        key = String(key_vals[0])
        values = [Bool(b) for b in key_vals[1:]]

        py_self[0].w[].messengerManager.update_bools_msg(key, values^)
        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_float_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        py_self[0].w[].messengerManager.update_float_msg(String(key_vals[0]), Float64(key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_floats_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        key = String(key_vals[0])
        values = [Float64(f) for f in key_vals[1:]]

        py_self[0].w[].messengerManager.update_floats_msg(key, values^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_int_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        py_self[0].w[].messengerManager.update_int_msg(String(key_vals[0]), Int64(key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_ints_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        key = String(key_vals[0])
        values = [Int64(v) for v in key_vals[1:]]

        py_self[0].w[].messengerManager.update_ints_msg(key, values^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_trig_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        py_self[0].w[].messengerManager.update_trig_msg(String(key_vals[0]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_trigs_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        key = String(key_vals[0])
        values = [Bool(b) for b in key_vals[1:]]

        py_self[0].w[].messengerManager.update_trigs_msg(key, values^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_string_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        py_self[0].w[].messengerManager.update_string_msg(String(key_vals[0]), String(key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_strings_msg(py_self: UnsafePointer[Self], key_vals: PythonObject) raises -> PythonObject:

        key = String(key_vals[0])
        texts = [String(s) for s in key_vals[1:]]

        py_self[0].w[].messengerManager.update_strings_msg(key, texts^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    fn get_audio_samples(mut self, loc_in_buffer: UnsafePointer[Float32], loc_out_buffer: UnsafePointer[Float64]) raises:

        self.w[].top_of_block = True
        self.w[].messengerManager.transfer_msgs()
                
        for i in range(self.w[].block_size):
            self.w[].block_state = i  # Update the block state

            if i == 1:
                self.w[].top_of_block = False
                self.w[].messengerManager.empty_msg_dicts()

            if self.w[].top_of_block:
                self.w[].print_counter += 1

            # fill the sound_in list with the current sample from all inputs
            for j in range(self.w[].num_in_chans):
                self.w[].sound_in[j] = Float64(loc_in_buffer[i * self.w[].num_in_chans + j]) 

            samples = self.graph.next()  # Get the next audio samples from the graph

            # Fill the wire buffer with the sample data
            for j in range(min(self.w[].num_out_chans, samples.__len__())):
                loc_out_buffer[i * self.w[].num_out_chans + j] = samples[Int(j)]

    @staticmethod
    fn next(py_self: UnsafePointer[Self], in_buffer: PythonObject, out_buffer: PythonObject) raises -> PythonObject:

        py_self[0].loc_in_buffer = in_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float32]()

        py_self[0].loc_out_buffer = out_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()
        # zero the output buffer
        for j in range(py_self[0].w[].num_out_chans):
            for i in range(py_self[0].w[].block_size):
                py_self[0].loc_out_buffer[i * py_self[0].w[].num_out_chans + j] = 0.0 

        py_self[0].get_audio_samples(py_self[0].loc_in_buffer, py_self[0].loc_out_buffer)  

        return PythonObject(None)  # Return a PythonObject wrapping the float value

# this is needed to make the module importable in Python - so simple!
@export
fn PyInit_GrainsBridge() -> PythonObject:
    try:
        var m = PythonModuleBuilder("MMMAudioBridge")

        _ = (
            m.add_type[MMMAudioBridge]("MMMAudioBridge").def_py_init[MMMAudioBridge.py_init]()
            .def_method[MMMAudioBridge.next]("next")
            .def_method[MMMAudioBridge.set_screen_dims]("set_screen_dims")
            .def_method[MMMAudioBridge.update_mouse_pos]("update_mouse_pos")
            .def_method[MMMAudioBridge.update_bool_msg]("update_bool_msg")
            .def_method[MMMAudioBridge.update_bools_msg]("update_bools_msg")
            .def_method[MMMAudioBridge.update_float_msg]("update_float_msg")
            .def_method[MMMAudioBridge.update_floats_msg]("update_floats_msg")
            .def_method[MMMAudioBridge.update_int_msg]("update_int_msg")
            .def_method[MMMAudioBridge.update_ints_msg]("update_ints_msg")
            .def_method[MMMAudioBridge.update_trig_msg]("update_trig_msg")
            .def_method[MMMAudioBridge.update_trigs_msg]("update_trigs_msg")
            .def_method[MMMAudioBridge.update_string_msg]("update_string_msg")
            .def_method[MMMAudioBridge.update_strings_msg]("update_strings_msg")
            .def_method[MMMAudioBridge.send_raw_hid]("send_raw_hid")
            .def_method[MMMAudioBridge.set_channel_count]("set_channel_count")
        )

        return m.finalize()
    except e:
        return abort[PythonObject](String("error creating Python Mojo module:", e))


