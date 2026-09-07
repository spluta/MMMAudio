from std.python import PythonObject
from std.python import Python
from std.python._cpython import PyGILState_STATE
from mmm_audio.constants import *
from mmm_audio.functions import py_to_float64
from mmm_audio.Oscillators import Phasor


struct GILGuard(Movable):
    """Holds the CPython GIL for the duration of a `with` block.

    `PyGILState_Ensure` is reference counted, so nesting guards is fine.
    """

    var state: PyGILState_STATE

    def __init__(out self):
        """Attach a thread state to this thread and take the GIL."""
        self.state = Python().cpython().PyGILState_Ensure()

    def __enter__(mut self) -> ref [self] Self:
        """Enter the `with` block. Returns a reference to the guard itself.
        
        Returns:
            A reference to the guard itself, which can be used to access the GIL state if needed.
        """
        return self

    def __exit__(mut self):
        """Release the GIL on the way out of the block."""
        Python().cpython().PyGILState_Release(self.state)

    def __exit__(mut self, error: Error) -> Bool:
        """Release the GIL when the block exits via an error, which keeps propagating.

        Args:
            error: The in-flight error, which this guard does not handle.

        Returns:
            False, so the error continues to propagate.
        """
        Python().cpython().PyGILState_Release(self.state)
        return False


struct MLP[input_size: Int = 2, output_size: Int = 16](Copyable, Movable): 
    """A Mojo wrapper for a PyTorch MLP model using Python interop.

    For example usage, see `TorchMlp.mojo` in the [Examples](../examples/index.md) folder.

    Parameters:
      input_size: The size of the input vector.
      output_size: The size of the output vector.
    """
    var world: World
    var py_input: PythonObject  
    var py_output: PythonObject  
    var model: PythonObject  
    var MLP: PythonObject  
    var torch: PythonObject  
    var model_input: Array[Float64, Self.input_size]  
    var model_output: Array[Float64, Self.output_size]  
    var fake_model_output: List[Float64]
    var inference_trig: Phasor[1]
    var inference_gate: Bool
    var trig_rate: Float64
    var messenger: Messenger
    var file_name: String

    def __init__(out self, world: World, file_name: String, namespace: Optional[String] = None, trig_rate: Float64 = 25.0):
        """Initialize the MLP struct.
        
        Args:
          world: Pointer to the MMMWorld.
          file_name: The path to the model file.
          namespace: Optional namespace for the Messenger.
          trig_rate: The rate in Hz at which to trigger inference.
        """
        self.world = world
        self.py_input = PythonObject(None) 
        self.py_output = PythonObject(None) 
        self.model = PythonObject(None)  
        self.MLP = PythonObject(None)  
        self.torch = PythonObject(None) 
        self.model_input = Array[Float64, Self.input_size](fill=0.0)
        self.model_output = Array[Float64, Self.output_size](fill=0.0)
        self.fake_model_output = [0.0 for _ in range(Self.output_size)]    
        self.inference_trig = Phasor[1](world)
        self.inference_gate = True
        self.trig_rate = trig_rate
        self.messenger = Messenger(world, namespace)
        self.file_name = String()

        try:
            self.MLP = Python.import_module("mmm_audio.MLP_Python")
            self.torch = Python.import_module("torch")
            self.py_input = self.torch.zeros(1, Self.input_size)  # Create a tensor with shape [1, 2] filled with zeros

            self.inference_gate = True
            print("Torch model loaded successfully")

        except ImportError:
            print("Error importing MLP_Python or torch module")

        self.reload_model(file_name)

    def reload_model(mut self, var file_name: String):
        """Reload the MLP model from a specified file.

        Args:
          file_name: The path to the model file.
        """
        try:
            with GILGuard():
                self.model = self.torch.jit.load(file_name)
                self.model.eval()
                for _ in range (5):
                    self.model(self.torch.randn(1, Self.input_size))  # I'm about to
            print("Torch model reloaded successfully")
        except _:
            print("Error reloading MLP model. Turning off inference.")
            self.inference_gate = False

    @always_inline
    def next(mut self):
        """Function for Audio Thread.

        Call this function every sample in the audio thread. The MLP will only
        perform inference at the rate specified by `trig_rate` (and if `inference_gate` is True).

        The model input is taken from `model_input`, and the output is written to `model_output`.
        """

        self.messenger.update("toggle_inference", self.inference_gate)
        
        if self.messenger.notify_update("load_mlp_training", self.file_name):
            var file_name = ""
            self.messenger.update("load_mlp_training", file_name)
            print("loading model from file: ", file_name)
            self.reload_model(file_name)

        if not self.inference_gate:
            if self.messenger.notify_update("fake_model_output", self.fake_model_output):
                comptime for i in range(self.output_size):
                    if i < len(self.fake_model_output):
                        self.model_output[Int(i)] = self.fake_model_output[i]
                        
        # do the inference only when triggered and the gate is on
        if self.inference_gate and self.inference_trig.next_bool(self.trig_rate):
            # Everything below touches CPython, the `is None` test included, so
            # the audio thread has to be holding the GIL for all of it.
            with GILGuard():
                if self.torch is None:
                    return

                try:
                    comptime for i in range(Self.input_size):
                        self.py_input[0][i] = self.model_input[Int(i)]
                    self.py_output = self.model(self.py_input)  # Run the model with the input

                    comptime for i in range(Self.output_size):
                        var py_val = self.py_output[0][i].item()
                        self.model_output[i] = Float64(py=py_val)
                except _:
                    print("Error processing input through MLP")
