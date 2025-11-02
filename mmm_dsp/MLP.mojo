from python import PythonObject
from python import Python
from mmm_dsp.Osc import Impulse
from mmm_utils.Messengers import *
from mmm_src.MMMWorld import MMMWorld
from mmm_src.MMMTraits import *

struct MLP[input_size: Int = 2, output_size: Int = 16](Messagable): 
    """
    A Mojo wrapper for a PyTorch MLP model using Python interop.

    ``MLP[input_size, output_size](world_ptr,file_name)``

    Parameters:
      input_size: The size of the input vector - defaults to 2.
      output_size: The size of the output vector - defaults to 16.
    """
    var world_ptr: UnsafePointer[MMMWorld]
    var py_input: PythonObject  
    var py_output: PythonObject  
    var model: PythonObject  
    var MLP: PythonObject  
    var torch: PythonObject  
    var model_input: InlineArray[Float64, input_size]  
    var model_output: InlineArray[Float64, output_size]  
    var fake_model_output: List[Float64]
    var inference_trig: Impulse
    var inference_gate: GateMsg
    var trig_rate: Float64
    var messenger: Messenger
    var file_name: TextMsg

    fn __init__(out self, world_ptr: UnsafePointer[MMMWorld], file_name: String, name_space: Optional[String] = None, trig_rate: Float64 = 25.0):
        self.world_ptr = world_ptr
        self.py_input = PythonObject(None) 
        self.py_output = PythonObject(None) 
        self.model = PythonObject(None)  
        self.MLP = PythonObject(None)  
        self.torch = PythonObject(None) 
        self.model_input = InlineArray[Float64, input_size](fill=0.0)
        self.model_output = InlineArray[Float64, output_size](fill=0.0)
        self.fake_model_output = List[Float64](0.0)    
        self.inference_trig = Impulse(self.world_ptr)
        self.inference_gate = GateMsg(True)
        self.trig_rate = trig_rate
        self.messenger = Messenger(world_ptr, name_space)
        self.file_name = TextMsg()

        try:
            # Python.add_to_path("neural_nets/MLP.py")
            self.MLP = Python.import_module("mmm_dsp.MLP")
            self.torch = Python.import_module("torch")
            self.py_input = self.torch.zeros(1, input_size)  # Create a tensor with shape [1, 2] filled with zeros
            self.model = self.torch.jit.load(file_name)  # Load your PyTorch model
            self.model.eval()  # Set the model to evaluation mode
            for _ in range (5):
                self.model(self.torch.randn(1, input_size))  # warm it up CHris

            self.inference_gate.state = True
            print("Torch model loaded successfully")

        except ImportError:
            print("Error importing MLP_py or torch module")
    
    fn register_messages(mut self):
        self.messenger.register(self.file_name, "load_mlp_training")
        self.messenger.register(self.inference_gate, "toggle_inference")
        self.messenger.register(self.fake_model_output, "fake_model_output")

    fn reload_model(mut self: MLP, var file_name: String):
        """
        Reload the MLP model from a specified file.

        Parameters:
          file_name: The path to the model file.
        """
        try:
            self.model = self.torch.jit.load(file_name)
            self.model.eval()
            for _ in range (5):
                self.model(self.torch.randn(1, input_size))  # I'm about to
            print("Torch model reloaded successfully")
        except Exception:
            print("Error reloading MLP model")

    fn __repr__(self) -> String:
        return String("MLP_Ugen(input_size: " + String(self.input_size) + ", output_size: " + String(self.output_size) + ")")

    @always_inline
    fn next(mut self: MLP):
        """
        Process the input through the MLP model.
            
        """
        self.messenger.update()
        if self.file_name:
            print("loading model from file: ", self.file_name.strings[0])
            self.reload_model(self.file_name.strings[0])

        if not self.inference_gate:
            # self.world_ptr[0].print(self.fake_model_output)
            for i in range(self.output_size):
                if i < len(self.fake_model_output):
                    self.model_output[Int(i)] = self.fake_model_output[i]

        # do the inference only when triggered and the gate is on
        if self.inference_gate and self.inference_trig.next_bool(self.trig_rate):
            if self.torch is None:
                return 
            try:
                for i in range(self.input_size):
                    self.py_input[0][i] = self.model_input[Int(i)]
                self.py_output = self.model(self.py_input)  # Run the model with the input
            except Exception:
                print("Error processing input through MLP")

            try:
                py_output = self.model(self.py_input)  # Run the model with the input
                for i in range(self.output_size):
                    self.model_output[Int(i)] = Float64(py_output[0][i].item())  # Convert each output to Float64
            except Exception:
                print("Error processing input through MLP:")