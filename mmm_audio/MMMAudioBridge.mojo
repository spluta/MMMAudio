# you should not edit this file
# i don't want it to be in this directory, but it needs to be here due to a mojo compiler bug

from python import PythonObject
from python import Python
from python.bindings import PythonModuleBuilder

from os import abort
from memory import *

from mmm_audio import *
from examples.FeedbackDelays import FeedbackDelays

struct MMMAudioBridge(Representable, Movable):
    var world: World
    var graph: FeedbackDelays  # The audio graph instance
    var block_counter: Int # count how many blocks this audio thread has been alive
    var np: PythonObject # an instance of numpy for sending np arrays back to python
    var pydict: PythonObject # a Python dictionary for sending messages back to python
    var osc_buffers: UnsafePointer[mut=True, OscBuffers, MutExternalOrigin] 
    var windows: UnsafePointer[mut=True, Windows, MutExternalOrigin] 

    @staticmethod
    fn py_init(out self: MMMAudioBridge, args: PythonObject, kwargs: PythonObject) raises:

        var sample_rate = Float64(py=args[0])
        var block_size: Int = Int(py=args[1])

        var num_out_chans: Int = 2
        var num_in_chans: Int = 2

        # right now if you try to read args[3], shit gets really weird

        self = Self(sample_rate, block_size, num_in_chans, num_out_chans)  # Initialize with sample rate, block size, and number of channels

    fn __repr__(self) -> String:
        return "MMMAudioBridge(world={self.world})"

    fn __init__(out self, sample_rate: Float64 = 44100.0, block_size: Int = 512, num_in_chans: Int = 12, num_out_chans: Int = 12):
        """Initialize the audio engine with sample rate, block size, and number of channels."""

        self.osc_buffers = alloc[OscBuffers](1)
        self.osc_buffers.init_pointee_move(OscBuffers())
        self.windows = alloc[Windows](1)
        self.windows.init_pointee_move(Windows())

        self.world = alloc[MMMWorld](1) 
        self.world.init_pointee_move(MMMWorld(sample_rate, block_size, num_in_chans, num_out_chans, self.osc_buffers, self.windows))

        self.graph = FeedbackDelays(self.world)

        self.block_counter = 0

        self.np = PythonObject(None)

        self.pydict = PythonObject(None)

        try:
            self.np = Python.import_module("numpy")
            self.pydict = Python.dict()
        except error:
            print("Error occurred while importing numpy. Error: ", error)

    @staticmethod
    fn set_channel_count(py_selfA: PythonObject, args: PythonObject) raises -> PythonObject:
        var num_in_chans = Int(py=args[0])
        var num_out_chans = Int(py=args[1])
        print("set_channel_count:", num_in_chans, num_out_chans)
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].set_channel_count(num_in_chans, num_out_chans)
    
        return None # PythonObject(None)

    @staticmethod
    fn set_screen_dims(py_selfA: PythonObject, dims: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].screen_dims = [Float64(py=dims[0]), Float64(py=dims[1])]  # Set the screen size in the MMMWorld instance

        return PythonObject(None) 

    @staticmethod
    fn update_mouse_pos(py_selfA: PythonObject, pos: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].mouse_x = Float64(py=pos[0])
        py_self[0].world[].mouse_y = Float64(py=pos[1])

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn to_float64(py_float: PythonObject) raises -> Float64:
        return Float64(py=py_float)

    @staticmethod
    fn update_bool_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].messengerManager.update_bool_msg(String(key_vals[0]), Bool(key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_bools_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        key = String(key_vals[0])
        values = [Bool(b) for b in key_vals[1:]]

        py_self[0].world[].messengerManager.update_bools_msg(key, values^)
        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_float_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].messengerManager.update_float_msg(String(key_vals[0]), Float64(py=key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_floats_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        key = String(key_vals[0])
        values = [Float64(py=f) for f in key_vals[1:]]

        py_self[0].world[].messengerManager.update_floats_msg(key, values^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_int_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].messengerManager.update_int_msg(String(key_vals[0]), Int(py=key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_ints_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        key = String(key_vals[0])
        values = [Int(py=v) for v in key_vals[1:]]

        py_self[0].world[].messengerManager.update_ints_msg(key, values^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_trig_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:
        var py_self = py_selfA.downcast_value_ptr[Self]()
        py_self[0].world[].messengerManager.update_trig_msg(String(key_vals[0]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_trigs_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:

        var py_self = py_selfA.downcast_value_ptr[Self]()

        key = String(key_vals[0])
        values = [Bool(b) for b in key_vals[1:]]

        py_self[0].world[].messengerManager.update_trigs_msg(key, values^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_string_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:

        var py_self = py_selfA.downcast_value_ptr[Self]()

        py_self[0].world[].messengerManager.update_string_msg(String(key_vals[0]), String(key_vals[1]))

        return PythonObject(None)  # Return a PythonObject wrapping None

    @staticmethod
    fn update_strings_msg(py_selfA: PythonObject, key_vals: PythonObject) raises -> PythonObject:

        var py_self = py_selfA.downcast_value_ptr[Self]()

        key = String(key_vals[0])
        texts = [String(s) for s in key_vals[1:]]

        py_self[0].world[].messengerManager.update_strings_msg(key, texts^)

        return PythonObject(None)  # Return a PythonObject wrapping None

    fn get_audio_samples(mut self, loc_in_buffer: MutUnsafePointer[Float32], mut loc_out_buffer: MutUnsafePointer[Float64]) raises:

        self.world[].top_of_block = True
        self.world[].messengerManager.transfer_msgs()
        self.world[].messengerManager.accepting_stream_data = False
        
        for i in range(self.world[].block_size):
            self.world[].block_state = i  # Update the block state

            if i == 1:
                self.world[].top_of_block = False
                self.world[].messengerManager.empty_msg_dicts()
            elif i == self.world[].block_size - 1 and self.block_counter % 10 == 0:
                # Add to the "stream" Dicts every 10 blocks. This is a hard coded throttling of sending
                # data back because otherwise it is way to much CPU (and not really necessary?)
                # Perhaps in the future the "10" can be turned into a user defined parameter when they
                # boot up an audio process. There might be times when a user would want to use the CPU
                # to stream back data every block.
                self.world[].messengerManager.accepting_stream_data = True

            if self.world[].top_of_block:
                self.world[].print_counter += 1
            # fill the sound_in list with the current sample from all inputs
            for j in range(self.world[].num_in_chans):
                self.world[].sound_in[j] = Float64(loc_in_buffer[i * self.world[].num_in_chans + j]) 

            samples = self.graph.next()  # Get the next audio samples from the graph

            # Fill the wire buffer with the sample data
            for j in range(min(self.world[].num_out_chans, samples.__len__())):
                loc_out_buffer[i * self.world[].num_out_chans + j] = samples[Int(j)]

    @staticmethod
    fn next(py_selfA: PythonObject, in_buffer: PythonObject, out_buffer: PythonObject) raises -> PythonObject:

        var py_self = py_selfA.downcast_value_ptr[Self]()

        loc_in_buffer = in_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float32]()

        loc_out_buffer = out_buffer.__array_interface__["data"][0].unsafe_get_as_pointer[DType.float64]()

        # zero the output buffer
        for j in range(py_self[0].world[].num_out_chans):
            for i in range(py_self[0].world[].block_size):
                loc_out_buffer[i * py_self[0].world[].num_out_chans + j] = 0.0 

        py_self[0].world[].messengerManager.reply_stream_float.clear()  # Clear the reply_stream_float dictionary at the start of each block
        py_self[0].world[].messengerManager.reply_stream_floats.clear()  # Clear the reply_stream_floats dictionary at the start of each block
        
        py_self[0].get_audio_samples(loc_in_buffer, loc_out_buffer)

        ############################################################################
        # Any data that needs to go back to Python needs to get into a Python.dict()
        ############################################################################
        # even though this is a lot of code right here inside the next function, I think
        # it's better to keep the Python.dict() pretty localized because I think a lot of the
        # overhead comes from dealing with Python objects.

        py_self[0].pydict.clear()

        # check the "reply_once" Dicts every block
        for pf in py_self[0].world[].messengerManager.reply_once_float.take_items():
            py_self[0].pydict[pf.key] = pf.value
        
        for pfs in py_self[0].world[].messengerManager.reply_once_floats.take_items():
            arr = py_self[0].np.empty(len(pfs.value),dtype=py_self[0].np.float64)
            for i in range(len(pfs.value)):
                arr[i] = pfs.value[i]
            py_self[0].pydict[pfs.key] = arr
        
        for pi in py_self[0].world[].messengerManager.reply_once_int.take_items():
            py_self[0].pydict[pi.key] = pi.value
        
        for pis in py_self[0].world[].messengerManager.reply_once_ints.take_items():
            arr = py_self[0].np.empty(len(pis.value),dtype=py_self[0].np.int64)
            for i in range(len(pis.value)):
                arr[i] = pis.value[i]
            py_self[0].pydict[pis.key] = arr
        
        for pb in py_self[0].world[].messengerManager.reply_once_bool.take_items():
            py_self[0].pydict[pb.key] = pb.value
        
        for ps in py_self[0].world[].messengerManager.reply_once_string.take_items():
            py_self[0].pydict[ps.key] = ps.value
        
        for pss in py_self[0].world[].messengerManager.reply_once_strings.take_items():
            arr = Python.list()
            for i in range(len(pss.value)):
                arr.append(pss.value[i])
            py_self[0].pydict[pss.key] = arr
        
        for pt in py_self[0].world[].messengerManager.reply_once_trig:
            py_self[0].pydict[pt] = None  # Set the key to True to indicate the trig was received
        
        py_self[0].world[].messengerManager.reply_once_trig.clear()

        if py_self[0].world[].messengerManager.accepting_stream_data:
                        
            # float
            for pf in py_self[0].world[].messengerManager.reply_stream_float.take_items():
                py_self[0].pydict[pf.key] = pf.value

            # floats
            for pfs in py_self[0].world[].messengerManager.reply_stream_floats.take_items():
                arr = py_self[0].np.empty(len(pfs.value),dtype=py_self[0].np.float64)
                for i in range(len(pfs.value)):
                    arr[i] = pfs.value[i]
                py_self[0].pydict[pfs.key] = arr

            # int
            for pi in py_self[0].world[].messengerManager.reply_stream_int.take_items():
                py_self[0].pydict[pi.key] = pi.value

            # ints
            for pis in py_self[0].world[].messengerManager.reply_stream_ints.take_items():
                arr = py_self[0].np.empty(len(pis.value),dtype=py_self[0].np.int64)
                for i in range(len(pis.value)):
                    arr[i] = pis.value[i]
                py_self[0].pydict[pis.key] = arr
            
            # bool
            for pb in py_self[0].world[].messengerManager.reply_stream_bool.take_items():
                py_self[0].pydict[pb.key] = pb.value
            
            # bools
            # for pbs in py_self[0].world[].messengerManager.reply_stream_bools.take_items():
            #     arr = py_self[0].np.empty(len(pbs.value),dtype=py_self[0].np.bool_)
            #     for i in range(len(pbs.value)):
            #         arr[i] = pbs.value[i]
            #     py_self[0].pydict[pbs.key] = arr
            
            # string
            for ps in py_self[0].world[].messengerManager.reply_stream_string.take_items():
                py_self[0].pydict[ps.key] = ps.value
            
            # strings
            for pss in py_self[0].world[].messengerManager.reply_stream_strings.take_items():
                arr = Python.list()
                for i in range(len(pss.value)):
                    arr.append(pss.value[i])
                py_self[0].pydict[pss.key] = arr
                        
        py_self[0].block_counter += 1
        return py_self[0].pydict

# this is needed to make the module importable in Python - so simple!
@export
fn PyInit_MMMAudioBridge() -> PythonObject:
    try:
        var m = PythonModuleBuilder("MMMAudioBridge")

        _ = m.add_type[MMMAudioBridge]("MMMAudioBridge").def_py_init[MMMAudioBridge.py_init]()
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
            .def_method[MMMAudioBridge.set_channel_count]("set_channel_count")

        return m.finalize()
    except e:
        _ = Error(String("error creating Python Mojo module: " + String(e)))
        abort()


